# Standalone system-app signing

Read this reference when preparing or diagnosing a standalone `hos_system_app` HAP. The
normal path is the bundled `scripts/system-app-sign.mjs` helper; use raw commands only to
diagnose a helper failure or to adapt the workflow to user-provided OEM material.

## Identity gates

Keep these properties separate:

- `app-distribution-type: os_integration` describes distribution and is not system identity.
- `bundle-info.app-feature: hos_system_app` establishes system-app identity for system APIs.
- `bundle-info.apl` must meet the permission's declared APL (`system_basic` or `system_core`).
- `acls.allowed-acls` must contain the complete set of ACL-eligible permissions requested
  above the app's ordinary grant level.
- The HAP signer must match `bundle-info.distribution-certificate` in the signed profile.
- The target image must trust the certificate chain. An emulator name or Release label alone
  does not prove whether it does.

## SDK development-signing mode

The helper uses only public development material bundled with a Full OpenHarmony SDK:

- `toolchains/lib/hap-sign-tool.jar`
- `toolchains/lib/OpenHarmony.p12`
- `toolchains/lib/OpenHarmonyProfileRelease.pem`
- `toolchains/lib/UnsgnedReleasedProfileTemplate.json` (the filename is historically misspelled)

It does not modify those files or copy the keystore into the project. It exports public CA
certificates, generates a CA-issued leaf/chain for the existing Application Release key,
creates a copied profile, and post-signs one exact unsigned HAP. This avoids both Huawei
account services and project `signingConfigs`.

The default SDK keystore password is passed to local tools but never printed. Generated
files belong in `.ohos-system-signing/` or another ignored project-local directory.

## Custom/OEM signing mode

The SDK development identity is not a substitute for production or OEM signing. If the
target image does not trust it, stop and ask the user for the intended signing arrangement:

- application keystore and key alias;
- complete application certificate chain;
- profile-signing key/certificate or an already signed profile;
- required APL and approved ACL set; and
- evidence that the target image trusts that chain or presets the application.

Do not copy, display, commit, or transform user passwords/private keys without explicit
authorization. Prefer paths or environment-backed secrets over command-line password values.

## Failure routing

| Signal | Meaning and next action |
| --- | --- |
| `202 Not System App` | Verify the embedded profile says `hos_system_app`; do not blame the image yet. |
| `9568289 grant request permissions failed` | Re-read permission metadata, APL, ACL eligibility, and the complete profile. |
| `9568332 install sign info inconsistent` | The installed bundle uses another signing identity. Stop before uninstalling. |
| `11013004 Profile cert must a cert chain` | The application certificate input is only a leaf or otherwise incomplete. |
| `11013002 certificate-chain signature mismatch` | Inspect Subject/Issuer relationships; do not permute or concatenate certificates blindly. |
| `11012005 Not support file` | Check accepted input/output suffixes. Use `.cer` for certificate-chain output and `.p7b` for profiles. |
| `verify-app` fails | Do not install. Preserve the helper work directory as diagnostic evidence. |
| Install succeeds but API fails | Compare the verified profile with `bm dump` and confirm the actual runtime caller. |

## Replacement safety

Install with replacement first:

```text
hdc -t <serial> install -r <verified-hap>
```

If signing information differs, do not automatically uninstall. Removing an existing system
or privileged bundle can destroy app data and can be dangerous for platform packages. Obtain
explicit approval for the exact bundle before `hdc uninstall` and then install fresh.

## Completion evidence

Keep signer verification, installation, Bundle Manager state, and runtime behavior as
separate proofs. A successful build, profile signature, or package installation alone does
not demonstrate that the target granted system identity or that the intended API works.
