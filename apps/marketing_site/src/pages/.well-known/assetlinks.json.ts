import type { APIRoute } from 'astro';

// Android App Links verification payload.
// SHA-256 fingerprint is a placeholder — replace with the actual upload
// keystore SHA-256 once the signing keystore is generated before Play Store
// upload. See apps/customer_app/android/app/build.gradle.kts for namespace.
export const GET: APIRoute = () => {
  const payload = [
    {
      relation: ['delegate_permission/common.handle_all_urls'],
      target: {
        namespace: 'android_app',
        package_name: 'com.suniltrading.app',
        sha256_cert_fingerprints: ['PLACEHOLDER'],
      },
    },
  ];

  return new Response(JSON.stringify(payload, null, 2), {
    headers: { 'Content-Type': 'application/json' },
  });
};
