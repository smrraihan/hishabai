import streamlit as st
import google.generativeai as genai
from dotenv import load_dotenv
import os
from PIL import Image

load_dotenv()

api_key = os.getenv("GEMINI_API_KEY")

genai.configure(api_key=api_key)

model = genai.GenerativeModel("gemini-2.5-flash")
col1, col2 = st.columns([1,5])

with col1:
    st.image("hishabAI_logo.png", width=60)

with col2:
    st.markdown(
        "<h1 style='margin-top:10px;'>HishabAI</h1>",
        unsafe_allow_html=True
    )

uploaded_file = st.file_uploader(
    "Upload or take screenshot of your transaction",
    type=["png", "jpg", "jpeg"]
)

if uploaded_file:

    image = Image.open(uploaded_file)

    col1, col2 = st.columns([1, 1])

    with col1:
        st.image(image, use_container_width=True)

    with col2:
        st.subheader("Extracted Information")

        if st.button("Extract Transaction"):

            prompt = """
            Analyze this image.
            
            If this is NOT a payment transaction screenshot,
            respond exactly:
            
            NOT_A_TRANSACTION_SCREENSHOT
            
            Otherwise extract:
            
            - Transaction Type
            - Merchant Name
            - Amount
            
            Return plain text only.
            """

            response = model.generate_content(
                [prompt, image]
            )
            
            if "NOT_A_TRANSACTION_SCREENSHOT" in response.text:
                st.error("This does not appear to be a payment screenshot.")
            else:
                st.success("Transaction found")
                st.write(response.text)
