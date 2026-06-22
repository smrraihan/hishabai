import streamlit as st
import google.generativeai as genai
from dotenv import load_dotenv
import io
import json
import logging
from PIL import Image
from datetime import datetime
import uuid

from services.drive_service import DriveConfigurationError, save_transaction


logger = logging.getLogger(__name__)

load_dotenv()

if "auth" not in st.secrets:
    st.error("Google sign-in is not configured yet.")
    st.info("Add the [auth] section to this app's Streamlit Cloud secrets.")
    st.stop()

if not st.user.is_logged_in:
    st.image("hishabAI_logo.png", width=90)
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

uploaded_file = st.file_uploader(
    "Upload or take screenshot of your transaction",
    type=["png", "jpg", "jpeg"]
)

if uploaded_file:
    uploaded_bytes = uploaded_file.getvalue()
    upload_key = f"{uploaded_file.name}:{len(uploaded_bytes)}"
    if st.session_state.get("upload_key") != upload_key:
        st.session_state["upload_key"] = upload_key
        st.session_state.pop("extracted_transaction", None)
        st.session_state.pop("receipt_id", None)
        st.session_state.pop("uploaded_at", None)
        st.session_state.pop("saved_receipt_id", None)
        st.session_state.pop("save_result", None)
        for key in (
            "review_amount",
            "review_transaction_type",
            "review_merchant_name",
            "review_transaction_date",
            "review_transaction_time",
            "review_trx_id",
            "review_category",
        ):
            st.session_state.pop(key, None)

    image = Image.open(io.BytesIO(uploaded_bytes))

    col1, col2 = st.columns([1, 1])

    with col1:
        st.image(image, use_container_width=True)

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

            try:
                response = model.generate_content([prompt, image])
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
                    for key in (
                        "review_amount",
                        "review_transaction_type",
                        "review_merchant_name",
                        "review_transaction_date",
                        "review_transaction_time",
                        "review_trx_id",
                        "review_category",
                    ):
                        st.session_state.pop(key, None)
                    st.session_state["extracted_transaction"] = result
                    st.session_state["receipt_id"] = str(uuid.uuid4())
                    st.session_state["uploaded_at"] = datetime.now().isoformat()
                    st.session_state.pop("saved_receipt_id", None)
                    st.session_state.pop("save_result", None)
                    st.success("Transaction found")
            except (json.JSONDecodeError, AttributeError):
                st.error("Could not parse Gemini response.")
                if "response" in locals():
                    st.code(response.text)
            except Exception:
                st.error("Gemini could not analyze this image. Please try again.")

        result = st.session_state.get("extracted_transaction")
        if result:
            st.subheader("Review & Correct")

            amount = st.text_input(
                "Amount", result.get("amount", ""), key="review_amount"
            )
            transaction_type = st.text_input(
                "Transaction Type",
                result.get("transaction_type", ""),
                key="review_transaction_type",
            )
            merchant_name = st.text_input(
                "Merchant Name",
                result.get("merchant_name", ""),
                key="review_merchant_name",
            )
            transaction_date = st.text_input(
                "Transaction Date",
                result.get("transaction_date", ""),
                key="review_transaction_date",
            )
            transaction_time = st.text_input(
                "Transaction Time",
                result.get("transaction_time", ""),
                key="review_transaction_time",
            )
            trx_id = st.text_input(
                "Transaction ID", result.get("trx_id", ""), key="review_trx_id"
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
                    "Other",
                ],
                key="review_category",
            )

            final_json = {
                "user_email": user_email,
                "receipt_id": st.session_state["receipt_id"],
                "image_file": uploaded_file.name,
                "uploaded_at": st.session_state["uploaded_at"],
                "amount": amount,
                "transaction_type": transaction_type,
                "merchant_name": merchant_name,
                "transaction_date": transaction_date,
                "transaction_time": transaction_time,
                "trx_id": trx_id,
                "category": category,
                "latitude": None,
                "longitude": None,
                "place_name": None,
            }

            st.subheader("JSON Preview")
            st.json(final_json)

            already_saved = (
                st.session_state.get("saved_receipt_id")
                == final_json["receipt_id"]
            )
            if st.button(
                "Save Receipt", type="primary", disabled=already_saved
            ):
                try:
                    with st.spinner("Saving receipt and transaction..."):
                        save_result = save_transaction(
                            final_json,
                            uploaded_bytes,
                            uploaded_file.type,
                            uploaded_file.name,
                        )
                    st.session_state["saved_receipt_id"] = final_json["receipt_id"]
                    st.session_state["save_result"] = save_result
                    st.rerun()
                except DriveConfigurationError as error:
                    st.error(str(error))
                except Exception:
                    logger.exception("Failed to save receipt to Google Drive")
                    st.error(
                        "Could not save to Google Drive. Check the app logs and "
                        "Drive folder permissions."
                    )

            save_result = st.session_state.get("save_result")
            if already_saved and save_result:
                st.success("Receipt, JSON, and spreadsheet row saved.")
