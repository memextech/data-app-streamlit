# Application Setup
- Update the following files to describe current application
- `pyproject.toml` - `name` and `description`
- `app.py` - `page_title` and `title`
- `README.md`

# How to run Data App
Use `start.sh`
Start script runs `uv sync` and `uv run`

# Data Sources

## CRITICAL: Read Before Implementation

1. **ALWAYS check this context.md file before implementing any feature**
2. **NEVER implement custom solutions for patterns documented here**
3. **ALWAYS use st.secrets for credentials, NEVER os.getenv()**

## Data Source Implementation - MANDATORY PATTERN

**CRITICAL**: ALL data source implementations MUST use Streamlit's st.connection pattern.
DO NOT implement custom connection code with gspread, psycopg2, etc.

### When implementing ANY data source:
1. Available connectors are listed in the system prompt under "Available Connectors" with their type and secret keys.
1. Check if a Streamlit connection exists for that source
2. Install the appropriate st-* connection package
3. Add connection config to `.streamlit/secrets.toml` using `$SECRET_KEY` references from the connector
4. Use st.connection() - NEVER custom clients
5. `setup_secrets()` is already called in `app.py` at startup - no additional setup needed do not remove
6. Use the connector-specific code pattern below based on the connector type

## Secret/Credential Access

**ALWAYS use st.secrets - NEVER use os.getenv() or environment variables directly**

✅ Correct: `spreadsheet_url = st.secrets["connections"]["gsheets"]["spreadsheet"]`
❌ Wrong: `spreadsheet_url = os.getenv("SAMPLE_SPREADSHEET")`

Secrets are configured in `.streamlit/secrets.toml` and ALWAYS should reference env vars with `$VAR_NAME` syntax.
The secrets_utils.py expands these automatically at startup.

## Caching Strategy

### @st.cache_resource - For connection objects (can't be pickled)
```python
@st.cache_resource
def get_connection():
    return st.connection("mydb", type=MyConnection)
```

### @st.cache_data - For data results (can be pickled)
```python
@st.cache_data
def load_tables(_conn):
    return _conn.query("SELECT table_name FROM information_schema.tables")

@st.cache_data(ttl=600)  # Cache for 10 minutes
def load_data(_conn, table_name):
    return _conn.query(f"SELECT * FROM {table_name}")
```

### Underscore prefix (_conn)
Tells Streamlit not to hash this parameter when caching. Use for connection objects passed to cached functions.

## Connector Types

### supabase
Install: `uv add st-supabase-connection`
secrets.toml:
```toml
[connections.supabase]
SUPABASE_URL = "$SUPABASE_URL"
SUPABASE_KEY = "$SUPABASE_KEY"
```
Usage:
```python
from st_supabase_connection import SupabaseConnection
import pandas as pd
conn = st.connection("supabase", type=SupabaseConnection)
result = conn.client.table("mytable").select("*").execute()
df = pd.DataFrame(result.data)
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
Using st.connection:
Install: `uv add st-gsheets-connection`
secrets.toml:
```toml
[connections.gsheets]
spreadsheet = "$GOOGLE_SHEET_URL"
```
Usage:
```python
from streamlit_gsheets import GSheetsConnection
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
from streamlit_gsheets import GSheetsConnection
conn = st.connection("gsheets", type=GSheetsConnection)
df = conn.read()
```


# Streamlit API Notes
- `use_container_width` is deprecated and will be removed in a future release. For `use_container_width=True`, use `width="stretch"`. For `use_container_width=False`, use `width="content"`.