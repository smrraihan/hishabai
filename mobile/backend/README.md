# hishabAI mobile backend

This Google Apps Script web app keeps Gemini and Google Drive credentials out of
the Android APK. It verifies the Google ID token on every request and derives the
owner email from that token.

## Deploy

1. Create a standalone project at <https://script.google.com> and paste
   `Code.gs` into it.
2. Open **Project settings > Script properties** and add:
   - `GEMINI_API_KEY`: the same Gemini key used by Streamlit.
   - `GOOGLE_WEB_CLIENT_ID`: the OAuth **Web application** client ID.
   - `ROOT_FOLDER_ID`: `18ZvATG26MrCJCMxNuagPuZ43sHyHsB-1`.
3. Click **Deploy > New deployment > Web app**.
4. Set **Execute as** to **Me** and **Who has access** to **Anyone**. Requests
   remain protected because the script validates a Google ID token itself.
5. Authorize Drive, Sheets, and external-request access, then copy the `/exec`
   URL.

When code changes, deploy a **new version** while keeping the same deployment.
Do not put the Gemini key or Drive refresh token in Flutter.
