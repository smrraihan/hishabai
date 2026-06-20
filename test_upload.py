from services.drive_service import upload_receipt

file_id = upload_receipt(
    "hishabAI_logo.png",
    "logo_test.png"
)

print(file_id)