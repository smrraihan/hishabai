from pydrive2.auth import GoogleAuth
from pydrive2.drive import GoogleDrive

print("1")

gauth = GoogleAuth()

print("2")

gauth.LoadClientConfigFile("client_secret.json")

print("3")

gauth.LocalWebserverAuth()

print("4")

drive = GoogleDrive(gauth)

print("SUCCESS")