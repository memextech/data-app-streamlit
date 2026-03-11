import streamlit as st
from secrets_utils import setup_secrets

# Setup secrets with environment variables
setup_secrets()

st.set_page_config(
    page_title="Streamlit App", layout="wide", initial_sidebar_state="collapsed"
)

st.title("Welcome to your Streamlit App")
st.markdown("Start building something amazing.")
