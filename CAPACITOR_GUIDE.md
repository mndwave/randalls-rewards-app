# Randalls Rewards — Capacitor App Guide

Server URL mode: the app loads `https://rewards.randalls.boldthin.gs` live.
Web deploys update the app instantly. Only rebuild the APK/IPA when native plugins or
platform manifests change.

## Repo structure

```
randalls-rewards-app/
├── capacitor.config.ts          # App ID, server URL, plugin config
├── android/                     # Android Studio project (Capacitor-managed)
├── ios/                         # Xcode project (Capacitor-managed; build on Mac)
├── www/index.html               # Placeholder only — server URL mode ignores this
└── randalls-rewards-release.keystore  # Android signing key (keep this)
```

**Web app lives in `~/randalls-rewards`** — that's where all feature code goes.

## App ID + domains

| Field | Value |
|---|---|
| App ID | `gs.boldthin.randalls.rewards` |
| Android package | `gs.boldthin.randalls.rewards` |
| iOS bundle ID | `gs.boldthin.randalls.rewards` |
| Server URL | `https://rewards.randalls.boldthin.gs` |
| Deep links | `/auth/verify` + `/login` |

## Bumping the version (when native changes require a rebuild)

Edit `APP_VERSION` in `capacitor.config.ts` — format `MAJOR.MINOR.PATCH`.
Then run `npx cap sync` before building.

## Everyday workflow

```bash
# After adding/updating a plugin:
npm install @capacitor/some-plugin
npx cap sync          # copies plugin into android/ + ios/

# After updating capacitor.config.ts:
npx cap sync

# Open Android Studio (requires Android Studio installed):
npx cap open android

# Open Xcode (Mac only):
npx cap open ios
```

## Android build (release APK)

```bash
npx cap sync
cd android
./gradlew assembleRelease
# APK: android/app/build/outputs/apk/release/app-release.apk
```

Signing is configured in `app/build.gradle` using `randalls-rewards-release.keystore`.

## iOS build (Mac only)

Requires:
1. Mac with Xcode 15+
2. Apple Developer Program membership (£79/yr)
3. `pod install` inside `ios/App/` (first time, or after plugin changes)

```bash
npx cap sync
# On Mac — open in Xcode:
npx cap open ios
# → Archive → Distribute App → App Store Connect
```

## Native plugins installed

| Plugin | Purpose |
|---|---|
| `@capacitor/app` | Deep link handling (magic-link auth opens app, not browser) |
| `@capacitor/haptics` | Tactile feedback on stamp earn events |
| `@capacitor/push-notifications` | FCM (Android) + APNs (iOS) loyalty notifications |
| `@capacitor/local-notifications` | Offline-capable scheduled alerts |
| `@capacitor/preferences` | Offline member state caching |
| `@capacitor/network` | Online/offline detection |
| `@capacitor/status-bar` | Status bar style (dark text on sand bg) |
| `@capacitor/keyboard` | Keyboard UX on login forms |
| `@capacitor/splash-screen` | Sand splash, no duration (web handles animation) |

## Web app integration (`~/randalls-rewards`)

- `src/lib/native.ts` — `isNative()`, `hapticSuccess()`, `hapticLight()`, `registerPushNotifications()`
- `src/components/NativeAppShell.tsx` — deep link handler + push registration (mounted in root layout)
- `src/app/globals.css` — `env(safe-area-inset-*)` padding on body + `.native-bottom-safe` class
- `src/components/StampCard.tsx` — haptic on stamp collect

## App Store justification

Features that distinguish this from a web view:
- **Push notifications** — iOS Safari push is unreliable; native = reliable loyalty alerts
- **Deep links** — magic-link emails open the app directly (not a browser tab)
- **Haptics** — tactile stamp feedback is impossible on web
- **Safe-area handling** — proper notch/home-indicator insets
- **Biometric re-auth** — future: FaceID/TouchID to replace magic-link per-session (add `@aparajita/capacitor-biometric-auth`)

## Google Play setup (when ready to submit)

1. Create app at play.google.com/console
2. App ID: `gs.boldthin.randalls.rewards`
3. Upload signed APK from `android/app/build/outputs/apk/release/`
4. Add `google-services.json` from Firebase console (for push notifications) to `android/app/`

## Push notifications setup

**Android (FCM):**
1. Create Firebase project at console.firebase.google.com
2. Add Android app with package `gs.boldthin.randalls.rewards`
3. Download `google-services.json` → place in `android/app/google-services.json`
4. `npx cap sync`
5. Server endpoint: `POST /api/push/register` receives `{ token, platform: 'android' }`

**iOS (APNs):**
1. Apple Developer → Certificates → APNs key (.p8)
2. Upload to Firebase console
3. Same server endpoint receives `{ token, platform: 'ios' }`
