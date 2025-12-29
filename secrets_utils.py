"""Utility to expand environment variables in st.secrets using singleton."""
import os
import streamlit as st
from streamlit.runtime.secrets import secrets_singleton


def _expand_value(value, key=None):
    """Recursively expand environment variables in values."""
    if isinstance(value, str):
        # If string starts with $, replace with env var
        if value.startswith('$'):
            var_name = value[1:]  # Remove the $
            env_value = os.getenv(var_name, value)  # Return original if not found
            
            # Special handling for GCP private_key - convert literal \n to actual newlines
            if key == "private_key" and env_value:
                env_value = env_value.replace("\\n", "\n")
            
            return env_value
        return value
    elif isinstance(value, dict):
        return {k: _expand_value(v, k) for k, v in value.items()}
    elif isinstance(value, list):
        return [_expand_value(item) for item in value]
    else:
        return value


def setup_secrets():
    """Expand environment variables in st.secrets singleton."""
    # Get current secrets as dict
    current_secrets = st.secrets.to_dict()
    
    # Expand all values
    expanded_secrets = _expand_value(current_secrets)
    
    # Update the singleton
    secrets_singleton._secrets = expanded_secrets