/** @type {import('jest').Config} */
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  rootDir: 'src',
  testMatch: ['**/*.test.ts', '**/*.spec.ts'],
  testTimeout: 30000,
  verbose: true,
  // Run test files sequentially so both can share the single Firestore
  // emulator without clearFirestore() in one file racing against seeding
  // in another. Both cross_tenant_integrity.test.ts (Firestore) and
  // cross_tenant_storage.test.ts (Storage, also seeds Firestore for
  // shopIsWritable lookups) call clearFirestore() in beforeEach.
  maxWorkers: 1,
};
