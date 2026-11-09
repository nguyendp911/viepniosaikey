# ViePN AI Keyboard

Native Swift iOS app and third-party keyboard extension, using offline template-based suggestions plus an optional HTTPS AI backend.

## Features

- Functional UIKit letter keyboard, shift, backspace, enter, spaces, keyboard switch.
- Intentional clipboard import (tap 📋 Dán); iOS may prompt for paste permission.
- Offline smart-reply heuristics and sample phrases shared with the companion app.
- Explicit-consent online AI reply generation via a private HTTPS backend.
- Tapping suggestion inserts text with `textDocumentProxy`; **does not auto-send**.
- App Group settings shared between app and extension.

## Requirements

- macOS with Xcode 16+, XcodeGen (`brew install xcodegen`)
- iOS 16+ device
- Apple Developer provisioning for both app and keyboard extension if installing IPA
- Both bundle IDs and App Group must be registered when using signing

## Generate and build

```bash
xcodegen generate
xcodebuild -project ViePNAIKeyboard.xcodeproj -scheme ViePNAIKeyboard -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

Install app, then open iOS Settings → General → Keyboard → Keyboards → Add New Keyboard → ViePN Keyboard. Full Access is necessary for network requests and clipboard features in the extension; the offline typing path remains usable without it.

## API backend

```bash
cd backend
python -m venv .venv
pip install -r requirements.txt
export GEMINI_API_KEY='your-secret-key'
export GEMINI_MODEL='gemini-2.5-flash'
uvicorn main:app --host 127.0.0.1 --port 8000
```

Deploy behind authenticated HTTPS infrastructure, protect /reply with server-side authentication and rate limits before public release, then configure your HTTPS URL in the iOS app. **Do not expose the sample backend publicly without authentication.** No AI provider key belongs in iOS source or GitHub.

## GitHub Actions

Push to main → unsigned simulator build. Manual Actions → iOS Build → Run workflow additionally attempts an ad-hoc IPA using environment `ios-signing` and GitHub secrets: `IOS_P12_BASE64`, `IOS_P12_PASSWORD`, `IOS_TEAM_ID`, `IOS_PROFILE_APP_BASE64`, `IOS_PROFILE_KEYBOARD_BASE64`, `IOS_APP_PROFILE_NAME`, `IOS_KEYBOARD_PROFILE_NAME`. Both provisioning profiles must include the App Group entitlement. Signing/export may require tailoring to your Apple Developer account.

## Honest limitations

- iOS custom keyboards cannot read chat bubbles in WhatsApp, Zalo, or Messenger. Copy a message, then explicitly paste inside ViePN.
- Keyboard text context is limited and some password fields require the system keyboard.
- Offline AI is **rule-based suggestions**, not an embedded large language model.
- Initial Vietnamese accent helper is a basic one-tap acute accent; a full Vietnamese Telex/VNI IME, autocorrect, layout polish, emoji, and accessibility auditing remain future work.
- No macOS/Xcode build was run in the authoring environment; CI is the first compile verification.

## Gemini

Create a Gemini key in Google AI Studio (https://aistudio.google.com/apikey). Store it only on your server as `GEMINI_API_KEY` and configure the keyboard HTTPS URL as `https://your-host/reply`. The default model is `gemini-2.5-flash` (override using `GEMINI_MODEL`). The `/health` endpoint is available for deployment checks. Public servers require authentication and rate limits; the reference backend currently has neither.


## Direct Gemini API key (Bring Your Own Key)

The companion iOS app now has **Gemini API - Nhập khóa trực tiếp**:
1. Generate a key at https://aistudio.google.com/apikey .
2. Paste it into the Gemini API Key field, select an accessible `gemini-2.5-flash` model (or another supported model), enable consent.
3. Tap **Kiểm tra Gemini API**; the keyboard's ☁️ AI button uses the same configuration after enabling Full Access.
4. No VPS or custom HTTPS URL is needed in direct mode.

Important: The direct key is stored in **App Group UserDefaults** for sharing with the extension (not Keychain), which is less secure than a server-side key. Never commit a key, share app container backups, or embed it in a redistributable IPA. Restrict the key and set usage caps in the Google Cloud console. For apps distributed to other people, a properly authenticated backend is safer.

The `backend/` directory remains available as an optional proxy for production deployments.
