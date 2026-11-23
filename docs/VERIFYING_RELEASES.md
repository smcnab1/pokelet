# Verify a Pokelet download

Use [official GitHub Releases](https://github.com/smcnab1/pokelet/releases). The selected release’s notes identify its installer, available verification files and signing/notarisation status. The [Wiki](https://github.com/smcnab1/pokelet/wiki/Verifying-Downloads) links here for the version-controlled verification procedure.

## Check the bytes

Download the DMG and its matching `.sha256` file from the same release. Keep their names unchanged and save them together. Set `dmg` to the exact installer filename shown under that release’s Assets:

```sh
cd "$HOME/Downloads"
dmg='EXACT-RELEASE-ASSET.dmg' # replace with the filename you downloaded
shasum -a 256 -c "$dmg.sha256"
```

Continue only if the expected installer reports `OK`. A missing file or mismatch is a stop condition. A checksum identifies file contents; a checksum from the download page alone does not authenticate the publisher.

## Check the publisher signature

For a release providing a detached Minisign signature, download its matching `.minisig` file into the same folder. Do not skip a missing or failed signature when the release promises one. Older checksum-only releases cannot provide this authentication.

1. Install [Minisign](https://jedisct1.github.io/minisign/), for example with `brew install minisign` if you already use Homebrew.
2. Obtain the [Pokelet public key](../security/pokelet-minisign.pub) from the official repository using **Download raw file**. Prefer a previously trusted copy and investigate any unexpected change; obtaining both key and installer from a compromised source would not establish trust.
3. In the same Terminal session, with `dmg` set as above and the key saved as `pokelet-minisign.pub`, run:

   ```sh
   shasum -a 256 -c "$dmg.sha256" &&
     minisign -Vm "$dmg" -p pokelet-minisign.pub
   ```

Both checks must succeed. Minisign should report `Signature and comment signature verified`. It confirms that the bytes match a signature from the corresponding private key, provided you trust the public key. It does not establish Apple Developer ID signing or notarisation.

## Install safely

Follow the [Wiki installation guide](https://github.com/smcnab1/pokelet/wiki/Installation) and the selected release’s first-launch instructions. An ad hoc app signature provides integrity without an Apple publisher identity. For unnotarised releases, use [Apple’s per-app guidance](https://support.apple.com/102445) only if you trust the source and verification passed. Keep Gatekeeper enabled; stop if macOS reports damage or malware.

For verification failures or unexpected key changes, use the [private security reporting route](../SECURITY.md). For installation questions, use [Discussions Q&A](https://github.com/smcnab1/pokelet/discussions/categories/q-a).
