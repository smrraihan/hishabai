import streamlit as st
import google.generativeai as genai
from dotenv import load_dotenv
import os
from PIL import Image

load_dotenv()

api_key = os.getenv("GEMINI_API_KEY")

st.write("API Key Found:", api_key is not None)

genai.configure(api_key=api_key)

model = genai.GenerativeModel("gemini-2.5-flash")

st.title("HishabAI MVP")

uploaded_file = st.file_uploader(
    "Upload bKash Screenshot",
    type=["png", "jpg", "jpeg"]
)

if uploaded_file:

    image = Image.open(uploaded_file)

    st.image(image)

    if st.button("Extract Transaction"):

        prompt = """
        Read this payment screenshot.

        Extract:

        - Transaction Type
        - Merchant Name
        - Amount

        Return only plain text.
        """

        response = model.generate_content(
            [prompt, image]
        )

        st.write(response.text)
