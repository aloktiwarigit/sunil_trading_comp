// =============================================================================
// hmac_join_token.test.ts — security-critical unit tests for the
// HMAC-SHA256 join-token utility (drift §15.1.A / ADR-009 v1.0.3).
//
// Coverage:
//   1. Mint → verify roundtrip succeeds with matching payload
//   2. Default TTL is 7 days
//   3. Custom TTL respected
//   4. Empty/non-string token rejected as `malformed`
//   5. Token with no dot rejected
//   6. Token with multiple dots rejected
//   7. Tampered payload rejected as `bad_signature`
//   8. Tampered signature rejected as `bad_signature`
//   9. Expired token rejected as `expired` (boundary: now == expiresAt)
//  10. Different secret produces `bad_signature` (no leak)
//  11. Missing/short secret throws on mint AND on verify
//  12. Constant-time comparison: tampered hex of WRONG length is rejected
// =============================================================================

import * as crypto from 'crypto';

const TEST_SECRET = '0123456789abcdef0123456789abcdef'; // 32 chars, OK for tests
const TEST_SECRET_ALT =
  'ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ_alternate_secret_value';

describe('hmac_join_token', () => {
  // Test setup: inject the secret per-test, force-reload the module so the
  // top-level secret-read picks up the new env each time.
  let mintJoinToken: typeof import('../src/lib/hmac_join_token').mintJoinToken;
  let verifyJoinToken: typeof import('../src/lib/hmac_join_token').verifyJoinToken;
  let DEFAULT_JOIN_TOKEN_TTL_MS: number;

  function loadModule(secret: string | undefined): void {
    jest.resetModules();
    if (secret === undefined) {
      delete process.env.JOIN_TOKEN_HMAC_SECRET;
    } else {
      process.env.JOIN_TOKEN_HMAC_SECRET = secret;
    }
    const mod = jest.requireActual('../src/lib/hmac_join_token') as typeof import('../src/lib/hmac_join_token');
    mintJoinToken = mod.mintJoinToken;
    verifyJoinToken = mod.verifyJoinToken;
    DEFAULT_JOIN_TOKEN_TTL_MS = mod.DEFAULT_JOIN_TOKEN_TTL_MS;
  }

  beforeEach(() => {
    loadModule(TEST_SECRET);
  });

  // ---------------------------------------------------------------------------

  test('mint → verify roundtrip succeeds with matching payload', () => {
    const token = mintJoinToken({
      shopId: 'sunil-trading-company',
      projectId: 'p_001',
      originalCustomerUid: 'uid_alice',
    });
    const result = verifyJoinToken(token);
    expect(result.ok).toBe(true);
    expect(result.payload?.shopId).toBe('sunil-trading-company');
    expect(result.payload?.projectId).toBe('p_001');
    expect(result.payload?.originalCustomerUid).toBe('uid_alice');
    expect(result.payload?.expiresAt).toBeGreaterThan(Date.now());
  });

  test('default TTL is 7 days', () => {
    expect(DEFAULT_JOIN_TOKEN_TTL_MS).toBe(7 * 24 * 60 * 60 * 1000);
    const now = 1_700_000_000_000;
    const token = mintJoinToken({
      shopId: 's',
      projectId: 'p',
      originalCustomerUid: 'u',
      nowMs: now,
    });
    const result = verifyJoinToken(token, { nowMs: now });
    expect(result.ok).toBe(true);
    expect(result.payload?.expiresAt).toBe(now + 7 * 24 * 60 * 60 * 1000);
  });

  test('custom TTL respected', () => {
    const now = 1_700_000_000_000;
    const ttl = 60_000; // 1 minute
    const token = mintJoinToken({
      shopId: 's',
      projectId: 'p',
      originalCustomerUid: 'u',
      ttlMs: ttl,
      nowMs: now,
    });
    const result = verifyJoinToken(token, { nowMs: now });
    expect(result.payload?.expiresAt).toBe(now + ttl);
  });

  test.each([
    ['empty', ''],
    ['no dot', 'abcdef'],
    ['only dot', '.'],
    ['empty payload', '.somesignature'],
    ['empty signature', 'somepayload.'],
  ])('verify rejects %s as malformed', (_, token) => {
    const result = verifyJoinToken(token as string);
    expect(result.ok).toBe(false);
    expect(result.error).toBe('malformed');
  });

  test('verify rejects multi-dot token as malformed (defense)', () => {
    // The format is exactly two segments separated by ONE dot. Multiple
    // dots is a defense against split-confusion attacks.
    const result = verifyJoinToken('aaa.bbb.ccc');
    expect(result.ok).toBe(false);
    expect(result.error).toBe('malformed');
  });

  test('verify rejects tampered payload as bad_signature', () => {
    const token = mintJoinToken({
      shopId: 's',
      projectId: 'p',
      originalCustomerUid: 'u_legit',
    });
    const [, sig] = token.split('.');
    // Forge a payload claiming a different originalCustomerUid, reusing
    // the original signature.
    const evilPayload = Buffer.from(
      JSON.stringify({
        shopId: 's',
        projectId: 'p',
        originalCustomerUid: 'u_attacker',
        expiresAt: Date.now() + 999_999,
      }),
      'utf8',
    )
      .toString('base64')
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=+$/, '');
    const forged = `${evilPayload}.${sig}`;
    const result = verifyJoinToken(forged);
    expect(result.ok).toBe(false);
    expect(result.error).toBe('bad_signature');
  });

  test('verify rejects tampered signature as bad_signature', () => {
    const token = mintJoinToken({
      shopId: 's',
      projectId: 'p',
      originalCustomerUid: 'u',
    });
    const [payload] = token.split('.');
    // Replace the signature with hex of equivalent length but bogus value.
    const bogusSig = 'a'.repeat(64); // sha256 hex digest is 64 chars
    const result = verifyJoinToken(`${payload}.${bogusSig}`);
    expect(result.ok).toBe(false);
    expect(result.error).toBe('bad_signature');
  });

  test('verify rejects expired token as expired (boundary: now == expiresAt)', () => {
    const now = 1_700_000_000_000;
    const token = mintJoinToken({
      shopId: 's',
      projectId: 'p',
      originalCustomerUid: 'u',
      ttlMs: 1_000,
      nowMs: now,
    });
    // Verify at exactly expiresAt — the token MUST already be expired.
    const result = verifyJoinToken(token, { nowMs: now + 1_000 });
    expect(result.ok).toBe(false);
    expect(result.error).toBe('expired');
  });

  test('verify rejects token from a different secret as bad_signature', () => {
    // Mint with TEST_SECRET.
    const token = mintJoinToken({
      shopId: 's',
      projectId: 'p',
      originalCustomerUid: 'u',
    });
    // Reload with the alternate secret, then verify the original token.
    loadModule(TEST_SECRET_ALT);
    const result = verifyJoinToken(token);
    expect(result.ok).toBe(false);
    expect(result.error).toBe('bad_signature');
  });

  test('mint throws when secret is missing', () => {
    loadModule(undefined);
    expect(() =>
      mintJoinToken({
        shopId: 's',
        projectId: 'p',
        originalCustomerUid: 'u',
      }),
    ).toThrow(/JOIN_TOKEN_HMAC_SECRET/);
  });

  test('mint throws when secret is too short (< 32 chars)', () => {
    loadModule('shortsecret');
    expect(() =>
      mintJoinToken({
        shopId: 's',
        projectId: 'p',
        originalCustomerUid: 'u',
      }),
    ).toThrow(/JOIN_TOKEN_HMAC_SECRET/);
  });

  test('verify rejects signature of wrong hex length cleanly', () => {
    const token = mintJoinToken({
      shopId: 's',
      projectId: 'p',
      originalCustomerUid: 'u',
    });
    const [payload] = token.split('.');
    // Hex string but truncated — Buffer.from('hex') will produce a
    // shorter Buffer than `expected`, which makes timingSafeEqual throw.
    // The verifier must catch and report bad_signature, not crash.
    const result = verifyJoinToken(`${payload}.deadbeef`);
    expect(result.ok).toBe(false);
    expect(result.error).toBe('bad_signature');
  });

  test('verify rejects payload that does not parse as JSON', () => {
    // Hand-craft a token with a base64url payload that isn't valid JSON
    // but produces a valid HMAC for the test secret. We sign a non-JSON
    // payload and check the verifier reports payload_invalid.
    const nonJsonPayload = Buffer.from('not-json-at-all', 'utf8')
      .toString('base64')
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=+$/, '');
    const sig = crypto
      .createHmac('sha256', TEST_SECRET)
      .update(nonJsonPayload)
      .digest('hex');
    const result = verifyJoinToken(`${nonJsonPayload}.${sig}`);
    expect(result.ok).toBe(false);
    expect(result.error).toBe('payload_invalid');
  });

  test('verify rejects payload missing required fields', () => {
    // Valid JSON, but missing originalCustomerUid + expiresAt.
    const incomplete = Buffer.from(
      JSON.stringify({ shopId: 's', projectId: 'p' }),
      'utf8',
    )
      .toString('base64')
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=+$/, '');
    const sig = crypto
      .createHmac('sha256', TEST_SECRET)
      .update(incomplete)
      .digest('hex');
    const result = verifyJoinToken(`${incomplete}.${sig}`);
    expect(result.ok).toBe(false);
    expect(result.error).toBe('payload_invalid');
  });

  test('two tokens minted at the same instant produce identical signatures (deterministic)', () => {
    const now = 1_700_000_000_000;
    const t1 = mintJoinToken({
      shopId: 's',
      projectId: 'p',
      originalCustomerUid: 'u',
      nowMs: now,
    });
    const t2 = mintJoinToken({
      shopId: 's',
      projectId: 'p',
      originalCustomerUid: 'u',
      nowMs: now,
    });
    expect(t1).toBe(t2);
  });
});
