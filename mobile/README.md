# hishabAI Android

Flutter Android client for hishabAI. Users sign in with Google, capture a
receipt, review Gemini-extracted fields, and save to the existing private Drive
folders and transaction spreadsheet through the Apps Script backend.

## Security model

- Gemini and Drive credentials are never included in the APK.
- The backend verifies a Google ID token for every operation.
- The backend derives `user_email` from that token; the phone cannot choose it.
- Receipt lists are filtered by verified email and never expose Drive URLs.

## One-time Google setup

1. Deploy `backend/Code.gs` using the instructions in `backend/README.md`.
2. In Google Cloud Console, create an OAuth client of type **Android**:
   - Package name: `com.hishabai.app`
   - SHA-1: run `./tool/print_release_sha1.sh` after creating the release key.
3. Keep the existing OAuth **Web application** client. Its client ID is used as
   `GOOGLE_WEB_CLIENT_ID` by both the backend and APK.
4. If the OAuth consent screen is in Testing mode, add each trusted tester under
   **Test users**.

## Build

Create `android/key.properties` and the JKS file as described in
`android/key.properties.example`. Copy `.release.env.example` to
`.release.env`, insert the real Apps Script `/exec` URL, then run:

```bash
flutter pub get
./tool/build_release.sh
```

The installable file is `build/app/outputs/flutter-apk/app-release.apk`.
