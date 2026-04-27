// =============================================================================
// hmac_join_token.ts — HMAC-SHA256 signed join token utility (ADR-009).
//
// Mints + verifies opaque, time-limited tokens that grant the bearer
// permission to call `joinDecisionCircle` for a specific shop/project on
// behalf of the original customer. The token is signed server-side with a
// secret stored in Firebase Secret Manager (`JOIN_TOKEN_HMAC_SECRET`) and
// verified server-side; clients treat it as opaque.
//
// Format:   `<base64url(payloadJson)>.<hex(hmac-sha256(payloadBase64))>`
//
// Payload:
//   {
//     shopId: string,
//     projectId: string,
//     originalCustomerUid: string,
//     expiresAt: number   // ms epoch
//   }
//
// Drift §15.1.A resolution.
// =============================================================================

import * as crypto from 'crypto';

export interface JoinTokenPayload {
  shopId: string;
  projectId: string;
  originalCustomerUid: string;
  /** Milliseconds since epoch. Tokens past this are rejected. */
  expiresAt: number;
}

/** 7 days in milliseconds — default TTL per ADR-009 v1.0.3. */
export const DEFAULT_JOIN_TOKEN_TTL_MS = 7 * 24 * 60 * 60 * 1000;

const SIGNATURE_ALGORITHM = 'sha256';

/**
 * Read the HMAC secret from the runtime env. Functions that mint or verify
 * tokens must declare `secrets: ['JOIN_TOKEN_HMAC_SECRET']` in their onCall
 * options so Firebase Secret Manager wires the env var at runtime.
 */
function readSecret(): string {
  const secret = process.env.JOIN_TOKEN_HMAC_SECRET;
  if (!secret || secret.length < 32) {
    // 32 chars = 256 bits at 1 char/byte. Anything shorter than that is
    // unsuitable for HMAC-SHA256 in production. The check fails loudly so
    // a missing or weak secret is caught at first use, not silently in the
    // forgery threat path.
    throw new Error(
      'JOIN_TOKEN_HMAC_SECRET is not set or is too short (>=32 chars). ' +
        'Set via `firebase functions:secrets:set JOIN_TOKEN_HMAC_SECRET` per ' +
        'docs/runbook/staging-setup.md.',
    );
  }
  return secret;
}

function base64UrlEncode(input: Buffer | string): string {
  const buf = typeof input === 'string' ? Buffer.from(input, 'utf8') : input;
  return buf
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

function base64UrlDecode(input: string): Buffer {
  const padded = input
    .replace(/-/g, '+')
    .replace(/_/g, '/')
    .padEnd(input.length + ((4 - (input.length % 4)) % 4), '=');
  return Buffer.from(padded, 'base64');
}

function signPayload(payloadBase64: string, secret: string): string {
  return crypto
    .createHmac(SIGNATURE_ALGORITHM, secret)
    .update(payloadBase64)
    .digest('hex');
}

/**
 * Mint a signed join token. Returns the opaque token string.
 *
 * Inputs are NOT sanitized here — callers are expected to validate
 * shopId / projectId / customerUid via existing rule-layer or callable-input
 * gates before requesting a token.
 */
export function mintJoinToken(input: {
  shopId: string;
  projectId: string;
  originalCustomerUid: string;
  /** Token lifetime in ms. Defaults to 7 days per ADR-009. */
  ttlMs?: number;
  /** For testing — override the "now" reference. */
  nowMs?: number;
}): string {
  const now = input.nowMs ?? Date.now();
  const ttl = input.ttlMs ?? DEFAULT_JOIN_TOKEN_TTL_MS;
  const payload: JoinTokenPayload = {
    shopId: input.shopId,
    projectId: input.projectId,
    originalCustomerUid: input.originalCustomerUid,
    expiresAt: now + ttl,
  };
  const payloadBase64 = base64UrlEncode(JSON.stringify(payload));
  const signature = signPayload(payloadBase64, readSecret());
  return `${payloadBase64}.${signature}`;
}

export type JoinTokenVerifyError =
  | 'malformed'
  | 'bad_signature'
  | 'expired'
  | 'payload_invalid';

export interface JoinTokenVerifyResult {
  ok: boolean;
  payload?: JoinTokenPayload;
  error?: JoinTokenVerifyError;
}

/**
 * Verify a join token.
 *
 * Returns `{ok: true, payload}` if the token is well-formed, the signature
 * matches, and the token has not expired. Returns `{ok: false, error}`
 * otherwise. Constant-time signature comparison is used to defeat timing
 * attacks.
 *
 * Callers MUST additionally check that the token's `shopId` (and where
 * relevant `projectId` / `originalCustomerUid`) match the surrounding
 * request context. The verifier proves the token is unforged + unexpired,
 * not that it's the right token for this request.
 */
export function verifyJoinToken(
  token: string,
  options: { nowMs?: number } = {},
): JoinTokenVerifyResult {
  if (typeof token !== 'string' || !token.includes('.')) {
    return { ok: false, error: 'malformed' };
  }

  const dotIndex = token.indexOf('.');
  // Reject if there are MULTIPLE dots — the format is exactly two segments.
  if (token.lastIndexOf('.') !== dotIndex) {
    return { ok: false, error: 'malformed' };
  }
  const payloadBase64 = token.slice(0, dotIndex);
  const signature = token.slice(dotIndex + 1);
  if (!payloadBase64 || !signature) {
    return { ok: false, error: 'malformed' };
  }

  let secret: string;
  try {
    secret = readSecret();
  } catch (err) {
    // Re-raise — a missing secret is an operational failure, not a token
    // verification failure. Don't swallow it as `bad_signature` (that
    // would mask the real cause).
    throw err;
  }

  const expected = signPayload(payloadBase64, secret);
  let signaturesMatch = false;
  try {
    signaturesMatch = crypto.timingSafeEqual(
      Buffer.from(signature, 'hex'),
      Buffer.from(expected, 'hex'),
    );
  } catch {
    // Buffer.from on an invalid hex string can throw, OR the buffers might
    // have different lengths (timingSafeEqual requires equal length). Either
    // way, the signature is bogus.
    return { ok: false, error: 'bad_signature' };
  }
  if (!signaturesMatch) {
    return { ok: false, error: 'bad_signature' };
  }

  let payload: JoinTokenPayload;
  try {
    const decoded = base64UrlDecode(payloadBase64).toString('utf8');
    payload = JSON.parse(decoded) as JoinTokenPayload;
  } catch {
    return { ok: false, error: 'payload_invalid' };
  }
  if (
    typeof payload.shopId !== 'string' ||
    typeof payload.projectId !== 'string' ||
    typeof payload.originalCustomerUid !== 'string' ||
    typeof payload.expiresAt !== 'number'
  ) {
    return { ok: false, error: 'payload_invalid' };
  }

  const now = options.nowMs ?? Date.now();
  if (now >= payload.expiresAt) {
    return { ok: false, error: 'expired' };
  }

  return { ok: true, payload };
}
