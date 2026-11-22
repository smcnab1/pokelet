# Verify and install Pokelet

Download Pokelet from [official GitHub Releases](https://github.com/smcnab1/pokelet/releases). The current public release is [Pokelet 1.1.0 Beta 1](https://github.com/smcnab1/pokelet/releases/tag/v1.1.0-beta.1). Its assets include a DMG and checksum.

## Check the download

1. Download the DMG and its matching `.sha256` file from the same release. Save both in Downloads and keep their filenames unchanged.
2. In Terminal, run the following for Beta 1. For a later release, replace the filename with the one you downloaded.

   ```sh
   cd "$HOME/Downloads"
   shasum -a 256 -c Pokelet-1.1.0-unnotarised.dmg.sha256
   ```

   Look for `Pokelet-1.1.0-unnotarised.dmg: OK`. A mismatch means you should stop and download the assets again.
3. Beta 1 provides checksum verification only. For a release documented as signed, download the matching `.minisig` asset to the same folder and complete the signature check below. Stop if the expected signature is missing.

## Verify a signed release

1. Install [Minisign](https://jedisct1.github.io/minisign/). If you already use Homebrew, run `brew install minisign`.
2. From the official repository, open the [Pokelet public key](../security/pokelet-minisign.pub) and use **Download raw file** to save it as `pokelet-minisign.pub` in Downloads. If you already have a trusted copy, use that copy and investigate any unexpected key change.
3. Set `dmg` to the exact filename on the release page. This example uses the planned Beta 2 installer filename.

   ```sh
   cd "$HOME/Downloads"
   dmg='Pokelet-1.2.0-build-3-Premium-Final-Test.dmg'
   shasum -a 256 -c "$dmg.sha256" &&
     minisign -Vm "$dmg" -p pokelet-minisign.pub
   ```

   Continue only if both checks succeed. Minisign should display `Signature and comment signature verified`.

SHA-256 identifies the file contents. A checksum from the download page alone cannot authenticate the publisher. Minisign confirms the bytes match a signature made by the holder of the corresponding private key, provided you obtained the public key through a trusted channel. The app’s ad hoc code signature provides integrity without an Apple Developer ID identity. Apple notarisation is a separate process.

## Install and open

1. Open the verified DMG, drag **Pokelet** to **Applications** and eject the disk image.
2. Open Pokelet from **Applications**. Beta 1 is unnotarised. If macOS blocks it because it cannot verify the developer, continue only if you trust the source and the verification checks passed. In **System Settings → Privacy & Security**, select **Open Anyway** if offered, then confirm. Leave Gatekeeper enabled. Stop if macOS reports damage or malware. [Apple’s first-launch guidance](https://support.apple.com/102445)
3. Select **Enable Pointer** from the hand icon in the menu bar. Read the [usage guide](README.md) for settings and shortcuts.
