# AGENT Context — koreader_remote_turner

## Goal
Build a Flutter app + KOReader plugin that listens to hardware volume buttons and sends page-turn/sleep signals to a connected KOReader client over WebSocket.

## Architecture
- **Flutter app** (Android/iOS/Linux/Windows/macOS): Runs a WebSocket server on-device, intercepts volume key presses at the platform level, maps them to actions via user-configurable key bindings, and sends them over WebSocket to KOReader.
- **KOReader plugin** (`remote_turner.koplugin/`): Pure-Lua WebSocket client that connects to the Flutter app, performs challenge-response auth, then listens for action messages (`page_forward`, `page_backward`, `sleep`).

## Stack
- **State**: kaeru + kaeru_ui (reactive `Ref`s, `Computed`, `Watch`, `KaeruWidget`)
- **UI**: Material 3, responsive (NavigationBar ≤720px / NavigationRail >720px), no AppBar, theme selector (Light/Dark/System)
- **Persistence**: shared_preferences (settings, theme), JSONL file (event logs)
- **WebSocket**: dart's `web_socket_channel` (server) + pure LuaSocket + custom RFC 6455 framing (client)
- **Auth**: SHA-256 challenge/response
- **L10n**: en, vi, ja, zh (ja/zh fall back to English)

## Key Files
| File | Purpose |
|------|---------|
| `lib/app.dart` | Root widget, responsive layout, keyboard routing, action dispatch via `useListen()` |
| `lib/main.dart` | MaterialApp entry point, theme mode stateful wrapper |
| `lib/models/server_state.dart` | All reactive state fields, `replayLogs()` for persistence |
| `lib/services/websocket_server.dart` | WebSocket server, auth, action dispatch + `recordEvent()` |
| `lib/services/keyboard_listener.dart` | Key mapping config, `Ref<KeyAction?> actionRef`, `actionForKey()` |
| `lib/services/platform_service.dart` | MethodChannel + EventChannel for platform volume events |
| `lib/services/event_logger.dart` | JSONL log persistence, `Ref<List<LogEntry>>` |
| `lib/services/password_auth.dart` | SHA-256 challenge/response |
| `lib/services/settings_service.dart` | Port, auto-start, theme mode getter/setter |
| `lib/pages/home_page.dart` | Cards layout: status + start/stop \| stats + mini log viewer, buttons disabled when disconnected |
| `lib/pages/logs_page.dart` | Log viewer with auto-scroll |
| `lib/pages/settings_page.dart` | Auto-save settings, theme SegmentedButton, DropdownMenu key mapping (60+ keys), auto-start toggle |
| `lib/pages/about_page.dart` | About page with URL ListTiles |
| `lib/widgets/connection_status.dart` | Status dot + text |
| `lib/l10n/app_*.arb` | Localization ARB files (en, vi, ja, zh) |
| `ios/Runner/AppDelegate.swift` | AVAudioSession volume KVO → EventChannel |
| `android/.../BackgroundService.kt` | Foreground service + MediaSession |
| `android/.../MainActivity.kt` | Method/EventChannel registration |
| `remote_turner.koplugin/main.lua` | Plugin entry: connect, auth, `registerCheckCallback`/`scheduleIn` fallback, action handlers |
| `remote_turner.koplugin/websocket.lua` | Pure-Lua RFC 6455 WebSocket client |

## kaeru_ui Patterns (all UI files use these)
| Pattern | Example |
|---------|---------|
| List → Row | `[a, b].row()` |
| List → Column | `[a, b].column(crossAxisAlignment: CrossAxisAlignment.start)` |
| Widget → Card | `widget.card()` |
| Widget → Padding | `widget.p(16)`, `.px(8)`, `.py(4)`, `.pt(8)` |
| Widget → Expanded | `widget.expand()` |
| Widget → Center | `widget.centered` |
| Widget → Scrollable | `widget.scrollable()` |
| String → styled Text | `'hello'.text.bold.size(16).gray(600).make()` |
| Localized → styled Text | `t.xxx.text.headlineSmall.make()` |
| IconData → Icon | `Icons.x.toIcon(size: 24, color: c)` |
| Spacing | `8.vSpace`, `12.hSpace` |
| Container builder | `widget.box.bg(c).rounded(8).border().p(12).make()` |

**Chain order**: `String → .text → VText chain → .make() → Text → Widget chain`  
**IMPORTANT**: `.centered` is on `Widget`, not `VText` — call after `.make()`.

## Critical Rules
- **`useContext()`** must be called **only** inside `KaeruWidget.setup()`, never inside `Computed` getters or `Watch` builder closures that fire after setup.
- **`LayoutBuilder`** inside a Kaeru builder must be wrapped in `Watch(() { … })`.
- LuaSocket `receive()` returns `(data, err)`, not `(ok, err)`.
- LuaJIT (Lua 5.1): no `|`/`&`/`~` — use `bit.bor()`, `bit.band()`, `bit.bxor()`.
- `challenge` variable must be captured by closure in Dart (pass-by-value bug fixed).
- `registerCheckCallback` not available in all KOReader versions — feature-detect and fall back to `scheduleIn(0.5, poll)` + `socket.select(timeout=0)`.
- `withOpacity` deprecated → use `withValues(alpha: ...)`.

## Verification
- `flutter analyze` — must pass with zero issues.
- KOReader plugin is symlinked: `remote_turner.koplugin/ → ~/.config/koreader/plugins/remote_turner.koplugin/`
- `flutter build apk` — requires Android SDK (not available in CI).

## Done
- All code written, all Dart analysis passes.
- Lua WebSocket client verified working (handshake, auth, non-blocking polling).
- Comprehensive `CONNECTION.md` documentation written.
- All UI pages refactored to kaeru_ui extension methods (`.row()`, `.card()`, `.expand()`, VText chains, etc.).
- All `StreamController`s replaced with kaeru `Ref` in services.
- Event counts persisted across restarts via log replay.
- Theme selector (Light/Dark/System), auto-start toggle, locale support (en/vi/ja/zh).

## Android Background Volume Interception
- **MediaSession `onVolumeKeyEvent` does NOT exist** in public Android SDK at any API level (wrong assumption, now removed).
- **`MainActivity.onKeyDown`** — works when app is in **foreground** (all API levels).
- **`VolumeKeyService`** — `AccessibilityService` that intercepts global volume keys via `onKeyEvent()` (API 18+). Must be enabled by user in Settings > Accessibility.
  - `VolumeKeyService.kt` at `android/app/src/main/kotlin/git/shin/koreader_remote_turner/`
  - Config at `android/app/src/main/res/xml/accessibility_service_config.xml`
  - Declaration in `AndroidManifest.xml` with `BIND_ACCESSIBILITY_SERVICE` permission
  - Flutter Settings page shows status + button to open Accessibility settings
- `actions/setup-java@v4` with `architecture: x64` on `windows-11-arm` runner fixes JNI arch mismatch (`jni` transitively pulled by `path_provider_android`).

## Critical Context
- `useContext()` must be called **only** inside a `KaeruWidget.setup()` function.
- `LayoutBuilder` inside a Kaeru builder must be wrapped in `Watch(() { … })`.
- VText chain order: `String → .text → VText chain → .make() → Text → Widget chain`.
- `KnownKeys.all` map lives in `keyboard_listener.dart` (65+ entries).
- `compileSdk = 36` in `android/app/build.gradle.kts` (required by `shared_preferences_android`, `url_launcher_android`, `androidx.core`).
- Windows Inno Setup uses `MyAppPlatform` define for arch-specific build path.
- Linux `build-deb.sh` uses platform mapping: amd64→x64, arm64→arm64.

## Next Steps
- Build & test on real Android device/emulator.
- iOS: `AVAudioSession` approach changes system volume + shows HUD — consider alternatives or document.
- Add unit/widget tests.
