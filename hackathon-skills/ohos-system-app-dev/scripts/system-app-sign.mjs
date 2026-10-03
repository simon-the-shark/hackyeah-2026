#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import { spawnSync } from 'node:child_process';
import { createHash, randomUUID, X509Certificate } from 'node:crypto';

const SDK_PASSWORD = '123456';
const VALIDITY_DAYS = 1095;
const ALLOWED_APLS = new Set(['system_basic', 'system_core']);

function usage() {
  return `Usage:
  node system-app-sign.mjs --project-dir <dir> --sdk-dir <api-dir> --hap <unsigned.hap>
    [--apl system_basic|system_core] [--acl <permission>]...
    [--work-dir <dir>] [--output <signed.hap>]
    [--java <path>] [--keytool <path>] [--force]

The script post-signs one exact unsigned HAP with the Full OpenHarmony SDK development
identity. It does not add signingConfigs, modify SDK files, install the HAP, or copy a
private key into the project.

Passwords default to the SDK development value. Override without command-line exposure via:
  OHOS_SYSTEM_STORE_PASSWORD
  OHOS_SYSTEM_KEY_PASSWORD
  OHOS_SYSTEM_ISSUER_KEY_PASSWORD
`;
}

function fail(message) {
  throw new Error(message);
}

function parseArgs(argv) {
  const options = { acls: [], apl: 'system_basic', force: false };
  const valueFlags = new Map([
    ['--project-dir', 'projectDir'],
    ['--sdk-dir', 'sdkDir'],
    ['--hap', 'hap'],
    ['--apl', 'apl'],
    ['--work-dir', 'workDir'],
    ['--output', 'output'],
    ['--java', 'java'],
    ['--keytool', 'keytool'],
  ]);

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === '--help' || arg === '-h') {
      options.help = true;
      continue;
    }
    if (arg === '--force') {
      options.force = true;
      continue;
    }
    if (arg === '--acl') {
      const value = argv[index + 1];
      if (!value || value.startsWith('--')) fail('--acl requires a permission name.');
      options.acls.push(value);
      index += 1;
      continue;
    }
    const key = valueFlags.get(arg);
    if (!key) fail(`Unknown argument: ${arg}`);
    const value = argv[index + 1];
    if (!value || value.startsWith('--')) fail(`${arg} requires a value.`);
    options[key] = value;
    index += 1;
  }
  options.acls = [...new Set(options.acls)];
  return options;
}

function stripJsonComments(text) {
  let output = '';
  let inString = false;
  let quote = '';
  let escaped = false;
  let lineComment = false;
  let blockComment = false;

  for (let index = 0; index < text.length; index += 1) {
    const current = text[index];
    const next = text[index + 1];

    if (lineComment) {
      if (current === '\n') {
        lineComment = false;
        output += current;
      }
      continue;
    }
    if (blockComment) {
      if (current === '*' && next === '/') {
        blockComment = false;
        index += 1;
      } else if (current === '\n') {
        output += current;
      }
      continue;
    }
    if (inString) {
      output += current;
      if (escaped) {
        escaped = false;
      } else if (current === '\\') {
        escaped = true;
      } else if (current === quote) {
        inString = false;
      }
      continue;
    }
    if (current === '"' || current === "'") {
      inString = true;
      quote = current;
      output += current;
      continue;
    }
    if (current === '/' && next === '/') {
      lineComment = true;
      index += 1;
      continue;
    }
    if (current === '/' && next === '*') {
      blockComment = true;
      index += 1;
      continue;
    }
    output += current;
  }
  return output;
}

function parseJson5Like(filePath) {
  const raw = fs.readFileSync(filePath, 'utf8').replace(/^\uFEFF/, '');
  const withoutComments = stripJsonComments(raw);
  const withoutTrailingCommas = withoutComments.replace(/,\s*([}\]])/g, '$1');
  try {
    return JSON.parse(withoutTrailingCommas);
  } catch (error) {
    fail(`Cannot parse ${filePath}. This helper supports the quoted-key JSON5 emitted by DevEco templates: ${error.message}`);
  }
}

function requireFile(filePath, description) {
  if (!fs.existsSync(filePath) || !fs.statSync(filePath).isFile()) {
    fail(`${description} not found: ${filePath}`);
  }
}

function resolveExecutable(explicitValue, windowsDefault, fallback) {
  if (explicitValue) return path.resolve(explicitValue);
  if (process.platform === 'win32' && windowsDefault && fs.existsSync(windowsDefault)) {
    return windowsDefault;
  }
  return fallback;
}

function run(executable, args, label) {
  const result = spawnSync(executable, args, {
    encoding: 'utf8',
    windowsHide: true,
    maxBuffer: 20 * 1024 * 1024,
  });
  const combined = `${result.stdout ?? ''}${result.stderr ?? ''}`;
  if (combined.trim()) process.stderr.write(combined.endsWith('\n') ? combined : `${combined}\n`);
  if (result.error) fail(`${label} could not start: ${result.error.message}`);
  if (result.status !== 0) fail(`${label} failed with exit code ${result.status}.`);
}

function numericSdkValue(value, fieldName) {
  const match = String(value ?? '').match(/\d+/);
  if (!match) fail(`${fieldName} is missing or is not numeric.`);
  return Number.parseInt(match[0], 10);
}

function removeOrRefuse(filePaths, force) {
  const existing = filePaths.filter((filePath) => fs.existsSync(filePath));
  if (existing.length > 0 && !force) {
    fail(`Generated output already exists. Re-run with --force to replace only these files:\n${existing.join('\n')}`);
  }
  for (const filePath of existing) {
    const stat = fs.statSync(filePath);
    if (!stat.isFile()) fail(`Refusing to replace non-file output: ${filePath}`);
    fs.unlinkSync(filePath);
  }
}

function certificateBlocks(chainText) {
  return chainText.match(/-----BEGIN CERTIFICATE-----[\s\S]*?-----END CERTIFICATE-----/g) ?? [];
}

function extractLeafCertificate(chainPath) {
  const blocks = certificateBlocks(fs.readFileSync(chainPath, 'utf8'));
  if (blocks.length < 3) fail(`Application certificate output is not a complete chain: ${chainPath}`);
  const parsed = blocks.map((pem) => ({ pem, certificate: new X509Certificate(pem) }));
  const leaf = parsed.find((entry) => !entry.certificate.ca);
  if (!leaf) fail(`No non-CA leaf certificate found in ${chainPath}.`);
  const leafIssuer = leaf.certificate.issuer;
  const issuerPresent = parsed.some((entry) => entry.certificate.subject === leafIssuer);
  if (!issuerPresent) fail('The generated application leaf issuer is absent from the certificate chain.');
  return `${leaf.pem.trim()}\n`;
}

function verifiedProfileContent(verificationPath) {
  const result = parseJson5Like(verificationPath);
  if (result.verifiedPassed === false) fail(`Profile verification failed: ${verificationPath}`);
  return result.content ?? result.profile ?? result;
}

function assertEmbeddedProfile(content, expected) {
  const bundleInfo = content['bundle-info'] ?? {};
  if (bundleInfo['bundle-name'] !== expected.bundleName) {
    fail(`Embedded profile bundle mismatch: expected ${expected.bundleName}, got ${bundleInfo['bundle-name']}.`);
  }
  if (bundleInfo.apl !== expected.apl) {
    fail(`Embedded profile APL mismatch: expected ${expected.apl}, got ${bundleInfo.apl}.`);
  }
  if (bundleInfo['app-feature'] !== 'hos_system_app') {
    fail(`Embedded profile is not hos_system_app: ${bundleInfo['app-feature']}.`);
  }
  const actualAcls = content.acls?.['allowed-acls'] ?? [];
  for (const acl of expected.acls) {
    if (!actualAcls.includes(acl)) fail(`Embedded profile is missing ACL: ${acl}`);
  }
}

function sha256(filePath) {
  const hash = createHash('sha256');
  hash.update(fs.readFileSync(filePath));
  return hash.digest('hex').toUpperCase();
}

function main() {
  const options = parseArgs(process.argv.slice(2));
  if (options.help) {
    process.stdout.write(usage());
    return;
  }
  if (!options.projectDir || !options.sdkDir || !options.hap) {
    fail(`--project-dir, --sdk-dir, and --hap are required.\n\n${usage()}`);
  }
  if (!ALLOWED_APLS.has(options.apl)) {
    fail(`--apl must be one of: ${[...ALLOWED_APLS].join(', ')}`);
  }

  const projectDir = path.resolve(options.projectDir);
  const sdkDir = path.resolve(options.sdkDir);
  const hapPath = path.resolve(projectDir, options.hap);
  const appJsonPath = path.join(projectDir, 'AppScope', 'app.json5');
  const buildProfilePath = path.join(projectDir, 'build-profile.json5');
  requireFile(appJsonPath, 'AppScope/app.json5');
  requireFile(buildProfilePath, 'build-profile.json5');
  requireFile(hapPath, 'Unsigned HAP');
  if (path.extname(hapPath).toLowerCase() !== '.hap') fail(`Input must be a .hap file: ${hapPath}`);

  const signTool = path.join(sdkDir, 'toolchains', 'lib', 'hap-sign-tool.jar');
  const keystore = path.join(sdkDir, 'toolchains', 'lib', 'OpenHarmony.p12');
  const profileCertificate = path.join(sdkDir, 'toolchains', 'lib', 'OpenHarmonyProfileRelease.pem');
  const profileTemplatePath = path.join(sdkDir, 'toolchains', 'lib', 'UnsgnedReleasedProfileTemplate.json');
  requireFile(signTool, 'hap-sign-tool.jar');
  requireFile(keystore, 'OpenHarmony.p12');
  requireFile(profileCertificate, 'OpenHarmonyProfileRelease.pem');
  requireFile(profileTemplatePath, 'UnsgnedReleasedProfileTemplate.json');

  const appJson = parseJson5Like(appJsonPath);
  const buildProfile = parseJson5Like(buildProfilePath);
  const bundleName = appJson.app?.bundleName;
  if (!bundleName) fail('AppScope/app.json5 does not contain app.bundleName.');
  const product = buildProfile.app?.products?.[0];
  if (!product) fail('build-profile.json5 does not contain app.products[0].');
  const compileVersion = numericSdkValue(product.compileSdkVersion, 'compileSdkVersion');
  const compatibleVersion = numericSdkValue(
    product.compatibleSdkVersion ?? product.targetSdkVersion ?? product.compileSdkVersion,
    'compatibleSdkVersion',
  );
  const selectedSdkVersion = numericSdkValue(path.basename(sdkDir), 'SDK directory name');
  if (selectedSdkVersion !== compileVersion) {
    fail(`SDK directory API ${selectedSdkVersion} does not match compileSdkVersion ${compileVersion}.`);
  }

  const workDir = path.resolve(options.workDir ?? path.join(projectDir, '.ohos-system-signing'));
  fs.mkdirSync(workDir, { recursive: true });
  const baseName = path.basename(hapPath, path.extname(hapPath));
  const outputHap = path.resolve(options.output ?? path.join(workDir, `${baseName}-system-signed.hap`));
  const outputRelative = path.relative(workDir, outputHap);
  if (outputRelative.startsWith('..') || path.isAbsolute(outputRelative)) {
    fail('--output must stay inside --work-dir. Select the desired artifact directory as --work-dir.');
  }
  const files = {
    rootCa: path.join(workDir, 'OpenHarmonyApplicationRootCA.cer'),
    applicationCa: path.join(workDir, 'OpenHarmonyApplicationCA.cer'),
    applicationChain: path.join(workDir, 'OpenHarmonySystemApplication.cer'),
    profileJson: path.join(workDir, 'system-profile.json'),
    signedProfile: path.join(workDir, 'system-profile.p7b'),
    profileVerification: path.join(workDir, 'system-profile-verification.json'),
    verifiedCertChain: path.join(workDir, 'verified-system-app-cert.cer'),
    embeddedProfile: path.join(workDir, 'verified-system-app-profile.p7b'),
    embeddedProfileVerification: path.join(workDir, 'verified-system-app-profile.json'),
    manifest: path.join(workDir, 'system-app-signing-result.json'),
    outputHap,
  };
  removeOrRefuse(Object.values(files), options.force);

  const java = resolveExecutable(
    options.java,
    'C:\\Program Files\\Huawei\\DevEco Studio\\jbr\\bin\\java.exe',
    'java',
  );
  const keytool = resolveExecutable(
    options.keytool,
    'C:\\Program Files\\Huawei\\DevEco Studio\\jbr\\bin\\keytool.exe',
    'keytool',
  );
  const storePassword = process.env.OHOS_SYSTEM_STORE_PASSWORD ?? SDK_PASSWORD;
  const keyPassword = process.env.OHOS_SYSTEM_KEY_PASSWORD ?? storePassword;
  const issuerKeyPassword = process.env.OHOS_SYSTEM_ISSUER_KEY_PASSWORD ?? storePassword;

  run(keytool, [
    '-exportcert', '-alias', 'openharmony application root ca',
    '-keystore', keystore, '-storepass', storePassword, '-file', files.rootCa,
  ], 'Export OpenHarmony Application Root CA');
  run(keytool, [
    '-exportcert', '-alias', 'openharmony application ca',
    '-keystore', keystore, '-storepass', storePassword, '-file', files.applicationCa,
  ], 'Export OpenHarmony Application CA');

  const certificateCn = bundleName.replace(/[^A-Za-z0-9._-]/g, '_').slice(0, 64);
  run(java, [
    '-jar', signTool, 'generate-app-cert',
    '-keyAlias', 'openharmony application release',
    '-keyPwd', keyPassword,
    '-issuer', 'C=CN,O=OpenHarmony,OU=OpenHarmony Team,CN=OpenHarmony Application CA',
    '-issuerKeyAlias', 'openharmony application ca',
    '-issuerKeyPwd', issuerKeyPassword,
    '-subject', `C=CN,O=OpenHarmony,OU=OpenHarmony Team,CN=${certificateCn}`,
    '-validity', String(VALIDITY_DAYS),
    '-signAlg', 'SHA256withECDSA',
    '-rootCaCertFile', files.rootCa,
    '-subCaCertFile', files.applicationCa,
    '-keystoreFile', keystore,
    '-keystorePwd', storePassword,
    '-outForm', 'certChain',
    '-outFile', files.applicationChain,
  ], 'Generate system application certificate chain');

  const profile = parseJson5Like(profileTemplatePath);
  const now = Math.floor(Date.now() / 1000);
  profile['version-name'] = appJson.app?.versionName ?? profile['version-name'] ?? '1.0.0';
  profile['version-code'] = appJson.app?.versionCode ?? profile['version-code'] ?? 1;
  profile.uuid = randomUUID();
  profile.validity = {
    'not-before': now - 300,
    'not-after': now + VALIDITY_DAYS * 24 * 60 * 60,
  };
  profile.type = 'release';
  profile['app-distribution-type'] = 'os_integration';
  profile['bundle-info'] = profile['bundle-info'] ?? {};
  profile['bundle-info']['bundle-name'] = bundleName;
  profile['bundle-info'].apl = options.apl;
  profile['bundle-info']['app-feature'] = 'hos_system_app';
  profile['bundle-info']['distribution-certificate'] = extractLeafCertificate(files.applicationChain);
  profile.acls = { 'allowed-acls': options.acls };
  profile.permissions = profile.permissions ?? { 'restricted-permissions': [] };
  profile.issuer = 'pki_internal';
  fs.writeFileSync(files.profileJson, `${JSON.stringify(profile, null, 2)}\n`, 'utf8');

  run(java, [
    '-jar', signTool, 'sign-profile',
    '-mode', 'localSign',
    '-keyAlias', 'openharmony application profile release',
    '-keyPwd', keyPassword,
    '-profileCertFile', profileCertificate,
    '-inFile', files.profileJson,
    '-signAlg', 'SHA256withECDSA',
    '-keystoreFile', keystore,
    '-keystorePwd', storePassword,
    '-outFile', files.signedProfile,
  ], 'Sign system profile');
  run(java, [
    '-jar', signTool, 'verify-profile',
    '-inFile', files.signedProfile,
    '-outFile', files.profileVerification,
  ], 'Verify signed system profile');
  assertEmbeddedProfile(verifiedProfileContent(files.profileVerification), {
    bundleName,
    apl: options.apl,
    acls: options.acls,
  });

  run(java, [
    '-jar', signTool, 'sign-app',
    '-mode', 'localSign',
    '-keyAlias', 'openharmony application release',
    '-keyPwd', keyPassword,
    '-appCertFile', files.applicationChain,
    '-profileFile', files.signedProfile,
    '-profileSigned', '1',
    '-inFile', hapPath,
    '-signAlg', 'SHA256withECDSA',
    '-keystoreFile', keystore,
    '-keystorePwd', storePassword,
    '-outFile', outputHap,
    '-compatibleVersion', String(compatibleVersion),
    '-signCode', '1',
  ], 'Sign HAP');
  run(java, [
    '-jar', signTool, 'verify-app',
    '-inFile', outputHap,
    '-outCertChain', files.verifiedCertChain,
    '-outProfile', files.embeddedProfile,
  ], 'Verify signed HAP');
  run(java, [
    '-jar', signTool, 'verify-profile',
    '-inFile', files.embeddedProfile,
    '-outFile', files.embeddedProfileVerification,
  ], 'Verify embedded HAP profile');
  assertEmbeddedProfile(verifiedProfileContent(files.embeddedProfileVerification), {
    bundleName,
    apl: options.apl,
    acls: options.acls,
  });

  const result = {
    verified: true,
    bundleName,
    apl: options.apl,
    appFeature: 'hos_system_app',
    acls: options.acls,
    compileVersion,
    compatibleVersion,
    unsignedHap: hapPath,
    signedHap: outputHap,
    sha256: sha256(outputHap),
    workDir,
    profileVerification: files.embeddedProfileVerification,
    certificateChain: files.verifiedCertChain,
  };
  fs.writeFileSync(files.manifest, `${JSON.stringify(result, null, 2)}\n`, 'utf8');
  process.stdout.write(`${JSON.stringify(result, null, 2)}\n`);
}

try {
  main();
} catch (error) {
  process.stderr.write(`[system-app-sign] ${error.message}\n`);
  process.exitCode = 1;
}
