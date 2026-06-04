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

**Android SDK (server-side builds):** SDK is at `~/android-sdk/` — NOT `/usr/lib/android-sdk/`
(that only has platform-tools). Set `sdk.dir=/home/mndwave/android-sdk` in `android/local.properties`.
Build credentials (keystore password, key alias) are in `~/seq1-healer/global.conf` under `[randalls_rewards_app]`.

## Publishing releases (Obtainium)

Obtainium tracks GitHub releases — a push to `main` does NOT update the app on device.
After building, always publish a release:

```bash
GH_TOKEN=<mndwave_pat> gh release create vX.Y.Z \
  android/app/build/outputs/apk/release/app-release.apk \
  --title "vX.Y.Z — description"
```

Bump `APP_VERSION` in `capacitor.config.ts` for every APK that goes to users (native change marker).

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

## 🚨 PLATFORM PARITY MANDATE — ZERO TOLERANCE

**Any native capability added to one platform MUST be mirrored on the other in the same commit.**

This includes: plugins, permissions, deep link schemes, push notification config, wallet integrations, biometrics, location, sharing — anything native. Capacitor's cross-platform shell (`~/randalls-rewards-app`) builds both iOS and Android simultaneously, so plugin installation is automatic. What requires deliberate mirroring:

- **Permissions**: AndroidManifest.xml ↔ Info.plist
- **Push / wallet / auth credentials**: separate per-platform setup (FCM vs APNs, Google Wallet vs Apple Wallet)
- **Platform-specific CSS/JS**: `html.ios-native` ↔ `html.android-native` rules must always be added as pairs
- **Safe area handling**: all `mobile-nav-trigger`, `mobile-nav-close`, `mobile-nav-drawer`, `qr-header` CSS rules apply to both

**Currently asymmetric (blocked externally — resolve when unblocked):**

| Feature | Android | iOS |
|---|---|---|
| Push notifications | ✅ FCM configured | ⏳ APNs pending Apple Dev account |
| Wallet | ✅ Google Wallet live | ⏳ Apple Wallet pending `.p12` cert + Apple Dev account |

**Deferred plugins (not yet needed, install on both when the feature ships):**

| Plugin | Use case |
|---|---|
| `@capacitor/geolocation` | "Find nearest venue" |
| `@capacitor/share` | Native share sheet for referral codes |
| `@capacitor/clipboard` | Clipboard write for referral code copy |
| `@aparajita/capacitor-biometric-auth` | FaceID/TouchID re-auth (replaces magic-link per-session) |

## Native plugins installed

| Plugin | Purpose |
|---|---|
| `@capacitor/app` | Deep link handling (magic-link auth opens app, not browser) |
| `@capacitor/haptics` | Tactile feedback on stamp earn events — iOS + Android ✓ |
| `@capacitor/push-notifications` | FCM (Android ✓) + APNs (iOS ⏳) |
| `@capacitor/local-notifications` | Offline-capable scheduled alerts — iOS + Android ✓ |
| `@capacitor/preferences` | Offline member state caching — iOS + Android ✓ |
| `@capacitor/network` | Online/offline detection — iOS + Android ✓ |
| `@capacitor/status-bar` | Status bar overlay config — iOS + Android ✓ |
| `@capacitor/keyboard` | Keyboard UX on login forms — iOS + Android ✓ |
| `@capacitor/splash-screen` | Sand splash on launch — iOS + Android ✓ |

## iOS Safe Area / Notch (2026-06-04 — all screens confirmed perfect)

**📖 Full detail:** `~/seq1-intelligence/memory/randalls-rewards/session-learnings-2026-06-04-ios-safe-area-notch-fix.md`

### What makes it work (three-part system):

**1. Native config** (`capacitor.config.ts`):
```typescript
ios: { contentInset: 'never' }          // web view fills full screen behind status bar
StatusBar: { overlaysWebView: true }     // no backgroundColor — web shows through
```

**2. Next.js layout** (`src/app/layout.tsx`):
```typescript
// themeColor MUST be here, NOT in metadata — otherwise Next.js 14 ignores viewportFit
export const viewport: Viewport = { themeColor: '#264f51', viewportFit: 'cover' }
```
`viewportFit: 'cover'` → `viewport-fit=cover` in the HTML → `env(safe-area-inset-top)` returns real notch height (~59px).

**3. NativeAppShell** (`src/components/NativeAppShell.tsx`):
```typescript
if (Capacitor.getPlatform() === 'ios') {
  // Belt-and-suspenders: also patch viewport meta at runtime
  vp.content += ', viewport-fit=cover'
  // CSS scoping class — all iOS-only rules use html.ios-native
  document.documentElement.classList.add('ios-native')
}
```

### CSS rules (globals.css):
```css
html.ios-native body { padding-top: env(safe-area-inset-top); }
html.ios-native .mobile-nav-trigger { top: calc(env(safe-area-inset-top) + 0.5rem); }
html.ios-native .mobile-nav-drawer  { padding-top: calc(env(safe-area-inset-top) + 1.75rem); }
```

### Per-page fixes:
- **QR page**: `useEffect` sets `body.backgroundColor = '#264f51'` on iOS so the dark gradient extends behind the notch. Resets on unmount.
- Hamburger: `absolute` positioned → not affected by body padding → explicit CSS rule.
- Nav drawer: `fixed top-0` background already fills notch; CSS rule adds safe area to content padding.

### 🚨 Anti-patterns (ZERO TOLERANCE):
- ❌ **NEVER import `@capacitor/status-bar` in the web app** — it's in the native shell only. Build fails silently on Vercel; old deploy serves forever.
- ❌ **NEVER put `themeColor` in `metadata`** when using `export const viewport` — Next.js 14 ignores the viewport export entirely.
- ❌ **NEVER rely on `body { padding-top }` for fixed/absolute elements** — they're viewport-relative and need explicit CSS rules.
- ❌ **Auto-deploy from GitHub does NOT work** — use CLI: `VERCEL_TOKEN=wm1K1pcXeqvqlSwUmmFJGfgg npx vercel --prod --token wm1K1pcXeqvqlSwUmmFJGfgg --yes`

## Web app integration (`~/randalls-rewards`)

- `src/lib/native.ts` — `isNative()`, `hapticSuccess()`, `hapticLight()`, `registerPushNotifications()`
- `src/components/NativeAppShell.tsx` — deep link handler + push registration + iOS safe area init
- `src/app/globals.css` — `html.ios-native` scoped safe-area rules + `.native-bottom-safe` class
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
