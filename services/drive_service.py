import io
import json
from pathlib import Path

import streamlit as st
from google.oauth2.credentials import Credentials as UserCredentials
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseUpload


ROOT_FOLDER_ID = "18ZvATG26MrCJCMxNuagPuZ43sHyHsB-1"
SPREADSHEET_NAME = "hishabAI Transactions"
DRIVE_SCOPE = "https://www.googleapis.com/auth/drive"
SHEETS_SCOPE = "https://www.googleapis.com/auth/spreadsheets"
SCOPES = [DRIVE_SCOPE, SHEETS_SCOPE]
SHEET_HEADERS = [
    "user_email",
    "receipt_id",
    "image_file",
    "uploaded_at",
    "amount",
    "transaction_type",
    "merchant_name",
    "transaction_date",
    "transaction_time",
    "trx_id",
    "category",
    "latitude",
    "longitude",
    "place_name",
    "receipt_drive_file_id",
    "receipt_drive_url",
    "json_drive_file_id",
    "json_drive_url",
]


class DriveConfigurationError(RuntimeError):
    pass


def _credentials_info():
    if "GOOGLE_DRIVE_CREDENTIALS" in st.secrets:
        value = st.secrets["GOOGLE_DRIVE_CREDENTIALS"]
        return json.loads(value) if isinstance(value, str) else dict(value)

    raise DriveConfigurationError(
        "Add GOOGLE_DRIVE_CREDENTIALS to the Streamlit app secrets."
    )


def _credentials():
    info = _credentials_info()

    if info.get("type") == "service_account":
        raise DriveConfigurationError(
            "Use the credentials_drive.json OAuth credential for this My Drive "
            "folder, not a service-account credential."
        )

    required = ("client_id", "client_secret", "refresh_token", "token_uri")
    if not all(info.get(key) for key in required):
        raise DriveConfigurationError(
            "The Drive OAuth credentials must contain a refresh token."
        )

    authorized_user_info = {key: info[key] for key in required}
    return UserCredentials.from_authorized_user_info(
        authorized_user_info, scopes=SCOPES
    )


def _services():
    credentials = _credentials()
    drive = build("drive", "v3", credentials=credentials, cache_discovery=False)
    sheets = build("sheets", "v4", credentials=credentials, cache_discovery=False)
    return drive, sheets


def _escape_query_value(value):
    return value.replace("\\", "\\\\").replace("'", "\\'")


def _find_child_folder(drive, folder_name):
    escaped_name = _escape_query_value(folder_name)
    result = drive.files().list(
        q=(
            f"'{ROOT_FOLDER_ID}' in parents and "
            "mimeType = 'application/vnd.google-apps.folder' and "
            f"name = '{escaped_name}' and trashed = false"
        ),
        fields="files(id, name)",
        pageSize=10,
    ).execute()
    folders = result.get("files", [])
    if not folders:
        raise DriveConfigurationError(
            f"The '{folder_name}' folder was not found inside the hishabAI folder."
        )
    return folders[0]["id"]


def _upload_bytes(drive, folder_id, name, content, mimetype):
    media = MediaIoBaseUpload(
        io.BytesIO(content), mimetype=mimetype, resumable=False
    )
    escaped_name = _escape_query_value(name)
    existing = drive.files().list(
        q=(
            f"'{folder_id}' in parents and name = '{escaped_name}' "
            "and trashed = false"
        ),
        fields="files(id)",
        pageSize=1,
    ).execute().get("files", [])
    if existing:
        return drive.files().update(
            fileId=existing[0]["id"],
            media_body=media,
            fields="id, webViewLink",
        ).execute()

    return drive.files().create(
        body={"name": name, "parents": [folder_id]},
        media_body=media,
        fields="id, webViewLink",
    ).execute()


def _get_or_create_spreadsheet(drive):
    escaped_name = _escape_query_value(SPREADSHEET_NAME)
    result = drive.files().list(
        q=(
            f"'{ROOT_FOLDER_ID}' in parents and "
            "mimeType = 'application/vnd.google-apps.spreadsheet' and "
            f"name = '{escaped_name}' and trashed = false"
        ),
        fields="files(id, webViewLink)",
        pageSize=10,
    ).execute()
    files = result.get("files", [])
    if files:
        return files[0]

    return drive.files().create(
        body={
            "name": SPREADSHEET_NAME,
            "mimeType": "application/vnd.google-apps.spreadsheet",
            "parents": [ROOT_FOLDER_ID],
        },
        fields="id, webViewLink",
    ).execute()


def _append_sheet_row(sheets, spreadsheet_id, record):
    existing = sheets.spreadsheets().values().get(
        spreadsheetId=spreadsheet_id, range="Sheet1!A:R"
    ).execute()
    values = existing.get("values", [])
    if not values:
        sheets.spreadsheets().values().update(
            spreadsheetId=spreadsheet_id,
            range="Sheet1!A1:R1",
            valueInputOption="RAW",
            body={"values": [SHEET_HEADERS]},
        ).execute()
    elif any(
        len(row) > 1 and row[1] == record["receipt_id"]
        for row in values[1:]
    ):
        return

    row = [record.get(header, "") for header in SHEET_HEADERS]
    sheets.spreadsheets().values().append(
        spreadsheetId=spreadsheet_id,
        range="Sheet1!A:R",
        valueInputOption="RAW",
        insertDataOption="INSERT_ROWS",
        body={"values": [row]},
    ).execute()


def save_transaction(record, receipt_bytes, receipt_mimetype, original_name):
    drive, sheets = _services()
    receipts_folder_id = _find_child_folder(drive, "receipts")
    json_folder_id = _find_child_folder(drive, "json")

    extension = Path(original_name).suffix.lower() or ".jpg"
    receipt_name = f"{record['receipt_id']}{extension}"
    receipt_file = _upload_bytes(
        drive,
        receipts_folder_id,
        receipt_name,
        receipt_bytes,
        receipt_mimetype or "application/octet-stream",
    )

    stored_record = dict(record)
    stored_record.update(
        {
            "image_file": receipt_name,
            "receipt_drive_file_id": receipt_file["id"],
            "receipt_drive_url": receipt_file.get("webViewLink", ""),
        }
    )

    json_content = json.dumps(
        stored_record, ensure_ascii=False, indent=2
    ).encode("utf-8")
    json_file = _upload_bytes(
        drive,
        json_folder_id,
        f"{record['receipt_id']}.json",
        json_content,
        "application/json",
    )
    stored_record.update(
        {
            "json_drive_file_id": json_file["id"],
            "json_drive_url": json_file.get("webViewLink", ""),
        }
    )

    spreadsheet = _get_or_create_spreadsheet(drive)
    _append_sheet_row(sheets, spreadsheet["id"], stored_record)
    return {
        "record": stored_record,
        "spreadsheet_url": spreadsheet.get("webViewLink", ""),
    }
