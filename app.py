import streamlit as st
import google.generativeai as genai
from dotenv import load_dotenv
import json
from PIL import Image
from datetime import datetime
import uuid
import pyrebase

load_dotenv()

firebase_project_id = st.secrets["FIREBASE_PROJECT_ID"]
firebase_config = {
    "apiKey": st.secrets["FIREBASE_API_KEY"],
    "authDomain": st.secrets["FIREBASE_AUTH_DOMAIN"],
    "projectId": firebase_project_id,
    "appId": st.secrets["FIREBASE_APP_ID"],
    # Pyrebase requires these keys even when only Firebase Auth is used.
    "databaseURL": f"https://{firebase_project_id}-default-rtdb.firebaseio.com",
    "storageBucket": f"{firebase_project_id}.appspot.com",
}

firebase = pyrebase.initialize_app(firebase_config)
auth = firebase.auth()

if "user_email" not in st.session_state:
    st.session_state["user_email"] = None


def show_auth_screen():
    st.title("Welcome to hishabAI")
    st.caption("Sign in to upload and organize your transactions.")

    sign_in_tab, create_account_tab = st.tabs(["Sign in", "Create account"])

    with sign_in_tab:
        with st.form("sign_in_form"):
            email = st.text_input("Email", key="sign_in_email")
            password = st.text_input(
                "Password", type="password", key="sign_in_password"
            )
            sign_in = st.form_submit_button("Sign in", type="primary")

        if sign_in:
            if not email or not password:
                st.error("Enter both your email and password.")
            else:
                try:
                    user = auth.sign_in_with_email_and_password(email, password)
                    st.session_state["user_email"] = user["email"]
                    st.rerun()
                except Exception:
                    st.error("Sign-in failed. Check your email and password.")

    with create_account_tab:
        with st.form("create_account_form"):
            new_email = st.text_input("Email", key="create_email")
            new_password = st.text_input(
                "Password (at least 6 characters)",
                type="password",
                key="create_password",
            )
            create_account = st.form_submit_button("Create account")

        if create_account:
            if not new_email or not new_password:
                st.error("Enter both your email and password.")
            elif len(new_password) < 6:
                st.error("Password must be at least 6 characters.")
            else:
                try:
                    auth.create_user_with_email_and_password(
                        new_email, new_password
                    )
                    user = auth.sign_in_with_email_and_password(
                        new_email, new_password
                    )
                    st.session_state["user_email"] = user["email"]
                    st.rerun()
                except Exception:
                    st.error(
                        "Account creation failed. The email may already be in use."
                    )


if st.session_state["user_email"] is None:
    show_auth_screen()
    st.stop()

user_email = st.session_state["user_email"]

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
    st.session_state["user_email"] = None
    st.rerun()

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
