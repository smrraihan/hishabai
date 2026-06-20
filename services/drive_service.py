from pydrive2.auth import GoogleAuth
from pydrive2.drive import GoogleDrive

RECEIPTS_FOLDER_ID = "1VxRyTVi_zhX70fHj42fnNMsSL_XM_3ls"


def get_drive():

    gauth = GoogleAuth()

    gauth.LoadCredentialsFile(
        "credentials_drive.json"
    )

    if gauth.access_token_expired:
        gauth.Refresh()
        gauth.SaveCredentialsFile(
            "credentials_drive.json"
        )

    return GoogleDrive(gauth)


def upload_receipt(
    local_file_path,
    file_name
):

    drive = get_drive()

    file = drive.CreateFile({
        "title": file_name,
        "parents": [
            {
                "id": RECEIPTS_FOLDER_ID
            }
        ]
    })

    file.SetContentFile(
        local_file_path
    )

    file.Upload()

    return file["id"]