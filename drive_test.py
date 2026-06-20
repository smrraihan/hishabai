from pydrive2.auth import GoogleAuth
from pydrive2.drive import GoogleDrive

RECEIPTS_FOLDER_ID = "1VxRyTVi_zhX70fHj42fnNMsSL_XM_3ls"

gauth = GoogleAuth()
gauth.LoadCredentialsFile("credentials_drive.json")

if gauth.credentials is None:
    print("Not authenticated")
elif gauth.access_token_expired:
    gauth.Refresh()
    gauth.SaveCredentialsFile("credentials_drive.json")

drive = GoogleDrive(gauth)

file = drive.CreateFile({
    "title": "test.txt",
    "parents": [{"id": RECEIPTS_FOLDER_ID}]
})

file.SetContentString("Hello hishabAI")
file.Upload()

print("SUCCESS")
print(file["id"])