import streamlit as st
import google.generativeai as genai
from dotenv import load_dotenv
import json
from PIL import Image
from datetime import datetime
import uuid

load_dotenv()

if "auth" not in st.secrets:
    st.error("Google sign-in is not configured yet.")
    st.info("Add the [auth] section to this app's Streamlit Cloud secrets.")
    st.stop()

if not st.user.is_logged_in:
    st.title("Welcome to hishabAI")
    st.caption("Sign in with your Google account to continue.")
    if st.button("Continue with Google", type="primary"):
        st.login()
    st.stop()

user_email = st.user.email

api_key = st.secrets["GEMINI_API_KEY"]

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

st.caption(f"Signed in as {user_email}")
if st.button("Log out"):
    st.logout()

# Upload
uploaded_file = st.file_uploader(
    "Upload or take screenshot of your transaction",
    type=["png", "jpg", "jpeg"]
)

if uploaded_file:

    image = Image.open(uploaded_file)

    col1, col2 = st.columns([1, 1])

    # Left side
    with col1:
        st.image(image, use_container_width=True)

    # Right side
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

                if result.get("is_transaction") is False:

                    st.error(
                        "This does not appear to be a payment screenshot."
                    )

                else:

                    st.success("Transaction found")

                    st.subheader("Review & Correct")

                    amount = st.text_input(
                        "Amount",
                        result.get("amount", "")
                    )

                    transaction_type = st.text_input(
                        "Transaction Type",
                        result.get("transaction_type", "")
                    )

                    merchant_name = st.text_input(
                        "Merchant Name",
                        result.get("merchant_name", "")
                    )

                    transaction_date = st.text_input(
                        "Transaction Date",
                        result.get("transaction_date", "")
                    )

                    transaction_time = st.text_input(
                        "Transaction Time",
                        result.get("transaction_time", "")
                    )

                    trx_id = st.text_input(
                        "Transaction ID",
                        result.get("trx_id", "")
                    )

                    category = st.selectbox(
                    "Category",
                    [
                        "Food",
                        "Transport",
                        "Shopping",
                        "Bills",
                        "Health",
                        "Entertainment",
                        "Education",
                        "Salary",
                        "Transfer",
                        "Investment",
                        "Other"
                    ]
                )
                    final_json = {
                        "user_email": user_email,
                        "receipt_id": str(uuid.uuid4()),
                        "image_file": uploaded_file.name,
                        "uploaded_at": datetime.now().isoformat(),
                        "amount": amount,
                        "transaction_type": transaction_type,
                        "merchant_name": merchant_name,
                        "transaction_date": transaction_date,
                        "transaction_time": transaction_time,
                        "trx_id": trx_id,
                        "category": category,
                        "latitude": None,
                        "longitude": None,
                        "place_name": None
                    }

                    st.subheader("JSON Preview")

                    st.json(final_json)

                    if st.button("Save Receipt"):
                        st.success("Ready to save")

            except Exception:

                st.error(
                    "Could not parse Gemini response."
                )

                st.code(response.text)
