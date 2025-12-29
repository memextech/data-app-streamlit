# Application Setup
- Update the following files to describe current application
- `pyproject.toml` - `name` and `description`
- `app.py` - `page_title` and `title`
- `README.md`

# How to run Data App
Use `start.sh`
Start script runs `uv sync` and `uv run`

# Data Sources

## Setup Pattern
Available connectors are listed in the system prompt under "Available Connectors" with their type and secret keys.
1. Add connection config to `.streamlit/secrets.toml` using `$SECRET_KEY` references from the connector
2. `setup_secrets()` is already called in `app.py` at startup - no additional setup needed do not remove
3. Use the connector-specific code pattern based on the connector type

## Connector Types

### supabase
Install: `uv add st-supabase-connection supabase`
secrets.toml:
```toml
[connections.supabase]
url = "$SUPABASE_URL"
key = "$SUPABASE_KEY"
```
Usage:
```python
from supabase import create_client
url = st.secrets["connections"]["supabase"]["url"]
key = st.secrets["connections"]["supabase"]["key"]
client = create_client(url, key)
result = client.table("table_name").select("*").execute()
```

### neon
Install: `uv add psycopg2-binary sqlalchemy`
secrets.toml:
```toml
[connections.neon]
url = "$NEON_DATABASE_URL"
```
Usage:
```python
conn = st.connection("neon", type="sql")
df = conn.query("SELECT * FROM table_name")
```

### bigquery
Install: `uv add google-cloud-bigquery pandas-gbq`
secrets.toml:
```toml
[gcp_service_account]
type = "service_account"
project_id = "$GCP_PROJECT_ID"
private_key_id = "$GCP_PRIVATE_KEY_ID"
private_key = "$GCP_PRIVATE_KEY"
client_email = "$GCP_CLIENT_EMAIL"
client_id = "$GCP_CLIENT_ID"
auth_uri = "https://accounts.google.com/o/oauth2/auth"
token_uri = "https://oauth2.googleapis.com/token"
auth_provider_x509_cert_url = "https://www.googleapis.com/oauth2/v1/certs"
client_x509_cert_url = "$GCP_CLIENT_X509_CERT_URL"
```
Usage:
```python
conn = st.connection("bigquery")
df = conn.query("SELECT * FROM dataset.table")
```

### google_sheet_public
Option A - Using st.connection:
Install: `uv add st-gsheets-connection`
secrets.toml:
```toml
[connections.gsheets]
spreadsheet = "$GOOGLE_SHEET_URL"
```
Usage:
```python
from st_gsheets_connection import GSheetsConnection
conn = st.connection("gsheets", type=GSheetsConnection)
df = conn.read()
```

### google_sheet_private
Install: `uv add st-gsheets-connection`
secrets.toml:
```toml
[connections.gsheets]
spreadsheet = "$GOOGLE_SHEET_URL"
type = "service_account"
project_id = "$GCP_PROJECT_ID"
private_key_id = "$GCP_PRIVATE_KEY_ID"
private_key = "$GCP_PRIVATE_KEY"
client_email = "$GCP_CLIENT_EMAIL"
client_id = "$GCP_CLIENT_ID"
auth_uri = "https://accounts.google.com/o/oauth2/auth"
token_uri = "https://oauth2.googleapis.com/token"
auth_provider_x509_cert_url = "https://www.googleapis.com/oauth2/v1/certs"
client_x509_cert_url = "$GCP_CLIENT_X509_CERT_URL"
```
Usage:
```python
from st_gsheets_connection import GSheetsConnection
conn = st.connection("gsheets", type=GSheetsConnection)
df = conn.read()
```


# Streamlit API Notes
- `use_container_width` is deprecated and will be removed in a future release. For `use_container_width=True`, use `width="stretch"`. For `use_container_width=False`, use `width="content"`.