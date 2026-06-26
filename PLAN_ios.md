# iOS POC — Implementation Guide

This guide gets the Mafia Local Flutter app running on a physical iPhone.
The codebase is already complete and iOS-ready; this is purely a setup and
deployment walkthrough.

---

## Prerequisites

| Requirement | Notes |
|---|---|
| Mac running macOS 13+ | iOS builds require macOS — no way around this |
| Xcode 15+ | Install from the Mac App Store (it's large, ~10 GB) |
| iPhone running iOS 14+ | iOS 14 is required for the local network permission |
| Apple ID | Free account is fine for personal device testing |
| CocoaPods | Installed via `sudo gem install cocoapods` |
| Flutter SDK | See Step 1 |

---

## Step 1 — Install Flutter on Mac

1. Download the Flutter SDK from https://docs.flutter.dev/get-started/install/macos
2. Unzip and move it somewhere permanent, e.g. `~/development/flutter`
3. Add Flutter to your PATH. In `~/.zshrc` (or `~/.bash_profile`):
   ```
   export PATH="$HOME/development/flutter/bin:$PATH"
   ```
4. Reload the shell: `source ~/.zshrc`
5. Verify: `flutter doctor`

Fix any issues `flutter doctor` reports before continuing. The two that matter
most are **Xcode** and **CocoaPods**.

---

## Step 2 — Accept Xcode licenses and install command-line tools

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
sudo xcodebuild -license accept
```

---

## Step 3 — Get the project

Clone or copy the `mafia_local` project onto your Mac. From the project root:

```bash
flutter pub get
```

---

## Step 4 — Install CocoaPods dependencies

```bash
cd ios
pod install
cd ..
```

This pulls in the native iOS dependencies for `network_info_plus` and
`web_socket_channel`. If `pod install` is slow, that's normal on first run.

---

## Step 5 — Configure Xcode signing

iOS apps must be code-signed even for development. This is a one-time setup.

1. Open the project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
   **Important:** always open the `.xcworkspace` file, not `.xcodeproj`.

2. In the Xcode sidebar, select **Runner** (top-level, blue icon).

3. Go to the **Signing & Capabilities** tab.

4. Under **Team**, sign in with your Apple ID and select your personal team
   (shows as "Your Name (Personal Team)").

5. Xcode will auto-generate a provisioning profile. If it shows an error about
   the bundle identifier already being taken, change the **Bundle Identifier**
   to something unique, e.g. `com.yourname.mafialocal`.

6. Close Xcode — Flutter will drive the build from the terminal.

---

## Step 6 — Connect your iPhone

1. Connect the iPhone via USB.
2. On the iPhone, tap **Trust** when the "Trust This Computer?" prompt appears.
3. Verify Flutter sees the device:
   ```bash
   flutter devices
   ```
   Your iPhone should appear in the list with an ID like `00008110-...`.

---

## Step 7 — Run the app

```bash
flutter run -d <your-iphone-id>
```

The first build takes 3–5 minutes. Subsequent runs are faster.

**First launch on device — trust the developer certificate:**

The app will install but won't open until you trust the certificate:

1. On iPhone: **Settings → General → VPN & Device Management**
2. Under "Developer App", tap your Apple ID email
3. Tap **Trust "your-email@example.com"**
4. Launch the app from the home screen

---

## Step 8 — iOS local network permission

On first launch, iOS will show a permission dialog:

> "Mafia Local" would like to find and connect to devices on your local network.

Tap **Allow**. Without this, the WebSocket server and client won't work.

If you accidentally tapped Deny:
**Settings → Privacy & Security → Local Network → toggle Mafia Local on**

---

## Step 9 — Test the full host ↔ joiner flow

You need two devices on the same Wi-Fi network (or one device hotspot).

**Device A (Host):**
1. Open the app → tap **Host**
2. Note the IP address and room code displayed on screen

**Device B (Joiner)** — can be another iPhone, Android phone, or the Mac
running `flutter run -d macos`:
1. Open the app → tap **Join**
2. Enter your name → tap **Next**
3. Enter Device A's IP and room code → tap **Join**

**Verify:**
- Device B's name appears in Device A's player list
- Tap "Send Test Message" on Device A → Device B's log updates
- Tap "Broadcast Message" on Device A → all joiners see it
- Tap "Send Message to Host" on Device B → Device A's log updates
- Force-close Device B's app → Device A's player list removes them

---

## Troubleshooting

**`pod install` fails with Ruby errors**
Run `sudo gem update --system` then retry.

**Xcode says "No account found"**
In Xcode → Settings → Accounts, sign in with your Apple ID.

**App installs but crashes immediately**
Check the bundle ID is unique (Step 5). Also make sure `pod install` completed
without errors.

**`network_info_plus` returns null for IP**
On iOS the WiFi IP can return null if the device is on cellular or if Wi-Fi
is off. Make sure the iPhone is connected to Wi-Fi, not using cellular.

**Joiner can't connect**
- Confirm both devices are on the same Wi-Fi network (not one on hotspot and
  one on home Wi-Fi)
- Confirm the local network permission is granted on both devices (Step 8)
- Double-check the IP and room code (room code is case-sensitive — all caps)
