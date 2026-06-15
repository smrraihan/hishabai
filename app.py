import streamlit as st
import google.generativeai as genai
from dotenv import load_dotenv
import os
import json
from PIL import Image

# Load environment variables
load_dotenv()

api_key = os.getenv("GEMINI_API_KEY")

genai.configure(api_key=api_key)

model = genai.GenerativeModel("gemini-2.5-flash")

# Header
col1, col2 = st.columns([0.7, 4])

with col1:
    st.image("hishabAI_logo.png", width=70)

with col2:
    st.markdown(
        "<h1 style='margin-top:0px;'>hishabAI</h1>",
        unsafe_allow_html=True
    )

# Upload
uploaded_file = st.file_uploader(
    "Upload or take screenshot of your transaction",
    type=["png", "jpg", "jpeg"]
)

if uploaded_file:

    image = Image.open(uploaded_file)

    col1, col2 = st.columns([1, 1])

    # Left side: Image
    with col1:
        st.image(image, use_container_width=True)

    # Right side: Results
    with col2:

        st.subheader("Extracted Information")

        if st.button("Extract Transaction"):

            prompt = """
            Analyze this image.

            If this is NOT a payment transaction screenshot,
            return exactly:

            {
              "is_transaction": false
            }

            If it IS a payment transaction screenshot,
            return ONLY valid JSON:

            {
              "is_transaction": true,
              "transaction_type": "",
              "merchant_name": "",
              "amount": "",
              "transaction_date": "",
              "transaction_time": "",
              "trx_id": ""
            }

            Do not return markdown.
            Do not use code blocks.
            Return JSON only.
            """

            response = model.generate_content(
                [prompt, image]
            )

            try:

                clean_text = response.text.strip()

                if clean_text.startswith("```json"):
                    clean_text = (
                        clean_text
                        .replace("```json", "")
                        .replace("```", "")
                        .strip()
                    )

                result = json.loads(clean_text)

                if result["is_transaction"] is False:

                    st.error(
                        "This does not appear to be a payment screenshot."
                    )

                else:

                    st.success("Transaction found")

                    st.metric(
                        "Amount",
                        result.get("amount", "N/A")
                    )

                    st.write("### Transaction Type")
                    st.write(
                        result.get("transaction_type", "N/A")
                    )

                    st.write("### Merchant Name")
                    st.write(
                        result.get("merchant_name", "N/A")
                    )

                    st.write("### Transaction Date")
                    st.write(
                        result.get("transaction_date", "N/A")
                    )

                    st.write("### Transaction Time")
                    st.write(
                        result.get("transaction_time", "N/A")
                    )

                    st.write("### Transaction ID")
                    st.write(
                        result.get("trx_id", "N/A")
                    )

            except Exception:

                st.error(
                    "Could not parse Gemini response."
                )

                st.code(response.text)