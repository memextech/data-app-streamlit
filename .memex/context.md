# Application Setup
- Update the following files to describe current application
- `pyproject.toml` - `name` and `description`
- `app.py` - `page_title` and `title`
- `README.md`

# How to run Data App
Use `start.sh`
Start script runs `uv sync` and `uv run`

# GitHub Setup
If a GitHub Connector is available (listed in "Available Connectors" in system prompt), use it. Otherwise, prompt the user to set up a GitHub Connector in Hub (instead of asking for secret directly).

When adding a git remote, ALWAYS use HTTPS URL with token (never SSH):

1. **Find the connector's secret key**: Check "Available Connectors" in system prompt for the exact secret key name (e.g., "PREFIX_GITHUB_TOKEN")
2. **Use that exact secret key**: Replace `{GITHUB_CONNECTOR_TOKEN}` with the actual secret key from step 1

```bash
git remote add origin https://[GITHUB_CONNECTOR_TOKEN]@github.com/[REPO-OWNER]/[REPO-NAME]
```

# Data Sources

## CRITICAL: Read Before Implementation

1. **ALWAYS check this context.md file before implementing any feature**
2. **NEVER implement custom solutions for patterns documented here**
3. **ALWAYS use st.secrets for credentials, NEVER os.getenv()**

## Data Source Implementation - MANDATORY PATTERN

**CRITICAL**: ALL data source implementations MUST use Streamlit's st.connection pattern.
DO NOT implement custom connection code with gspread, psycopg2, etc.

### When implementing ANY data source:
1. Available connectors are listed in the system prompt under "Available Connectors" with their type and secret keys that match environment variables.
1. Check if a Streamlit connection exists for that source
2. Install the appropriate st-* connection package
3. Add connection config to `.streamlit/secrets.toml` using exact secret keys / env vars references from the connector
4. Use st.connection() - NEVER custom clients
5. `setup_secrets()` is already called in `app.py` at startup - no additional setup needed do not remove
6. Use the connector-specific code pattern below based on the connector type

## Secret/Credential Access

**ALWAYS use st.secrets - NEVER use os.getenv() or environment variables directly**

✅ Correct: `spreadsheet_url = st.secrets["connections"]["gsheets"]["spreadsheet"]`
❌ Wrong: `spreadsheet_url = os.getenv("SAMPLE_SPREADSHEET")`

Secrets are configured in `.streamlit/secrets.toml` and ALWAYS should reference env vars with `$VAR_NAME` syntax.
The secrets_utils.py expands these automatically at startup.
Only replace values starting with `$` with the connector's secret keys/env vars. Keep literal values like `"service_account"` or URLs unchanged.

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

## File Uploads

When the user mentions a file using the `@filename` syntax (file-mention), the agent must:

1. Extract the file label and path from the mention
2. Add the file to `.streamlit/secrets.toml` under `[files]`:
   ```toml
   [files]
   "my file name.csv" = "/data/users/.../uploads/my file name.csv"
   ```
3. Access the file path in code using `st.secrets["files"]["my file name.csv"]`
4. Load the file using pandas or appropriate library:
   ```python
   import pandas as pd

   path = st.secrets["files"]["my file name.csv"]
   df = pd.read_csv(path)
   ```

### File mention format
File mentions appear in prompts as:
```html
<span data-file-mention="" class="file-mention" data-id="..." data-label="my file name.csv.csv" data-path="/data/users/.../uploads/my file name.csv.csv">my file name.csv.csv</span>
```

Extract:
- **data-label**: Use as the key in `[files]`
- **data-path**: Use as the value (the actual file path)

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
url = "$URL"
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
project_id = "$PROJECT_ID"
private_key_id = "$PRIVATE_KEY_ID"
private_key = "$PRIVATE_KEY"
client_email = "$CLIENT_EMAIL"
client_id = "$CLIENT_ID"
auth_uri = "https://accounts.google.com/o/oauth2/auth"
token_uri = "https://oauth2.googleapis.com/token"
auth_provider_x509_cert_url = "https://www.googleapis.com/oauth2/v1/certs"
client_x509_cert_url = "$CLIENT_X509_CERT_URL"
```

**Note**: The `secrets_utils.py` automatically handles converting literal `\n` in the private_key to actual newlines.

Usage:
```python
from google.oauth2 import service_account
from google.cloud import bigquery
import pandas as pd

# Create API client
credentials = service_account.Credentials.from_service_account_info(
    st.secrets["gcp_service_account"]
)
client = bigquery.Client(credentials=credentials)

# Perform query
@st.cache_data(ttl=600)
def run_query(query):
    query_job = client.query(query)
    rows_raw = query_job.result()
    # Convert to list of dicts for caching
    rows = [dict(row) for row in rows_raw]
    return rows

# Use the query
rows = run_query("SELECT * FROM `dataset.table` LIMIT 1000")
df = pd.DataFrame(rows)
```

### google_sheet_public
Using st.connection:
Install: `uv add st-gsheets-connection`
secrets.toml:
```toml
[connections.gsheets]
spreadsheet = "$SPREADSHEET"
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
spreadsheet = "$SPREADSHEET"
type = "service_account"
project_id = "$PROJECT_ID"
private_key_id = "$PRIVATE_KEY_ID"
private_key = "$PRIVATE_KEY"
client_email = "$CLIENT_EMAIL"
client_id = "$CLIENT_ID"
auth_uri = "https://accounts.google.com/o/oauth2/auth"
token_uri = "https://oauth2.googleapis.com/token"
auth_provider_x509_cert_url = "https://www.googleapis.com/oauth2/v1/certs"
client_x509_cert_url = "$CLIENT_X509_CERT_URL"
```
Usage:
```python
from streamlit_gsheets import GSheetsConnection
conn = st.connection("gsheets", type=GSheetsConnection)
df = conn.read()
```

### aws_s3
Install: `uv add s3fs st-files-connection`
secrets.toml:
```toml
AWS_ACCESS_KEY_ID = "$AWS_ACCESS_KEY_ID"
AWS_SECRET_ACCESS_KEY = "$AWS_SECRET_ACCESS_KEY"
AWS_DEFAULT_REGION = "$AWS_DEFAULT_REGION"
```
Usage:
```python
from st_files_connection import FilesConnection
conn = st.connection(
        's3',
        type=FilesConnection,
        key=st.secrets["AWS_ACCESS_KEY_ID"],
        secret=st.secrets["AWS_SECRET_ACCESS_KEY"],
        client_kwargs={'region_name': st.secrets["AWS_DEFAULT_REGION"]}
    )
df = conn.read("testbucket/myfile.csv", input_format="csv", ttl=600)
```

### mssql
Install: `uv add pyodbc`
secrets.toml:
```toml
[mssql]
server = "$SERVER"
database = "$DATABASE"
username = "$USERNAME"
password = "$PASSWORD"
```
Usage:
```python
import pyodbc

@st.cache_resource
def init_connection():
    return pyodbc.connect(
        "DRIVER={ODBC Driver 17 for SQL Server};SERVER="
        + st.secrets["mssql"]["server"]
        + ";DATABASE=" + st.secrets["mssql"]["database"]
        + ";UID=" + st.secrets["mssql"]["username"]
        + ";PWD=" + st.secrets["mssql"]["password"]
    )

conn = init_connection()

@st.cache_data(ttl=600)
def run_query(query):
    with conn.cursor() as cur:
        cur.execute(query)
        return cur.fetchall()

rows = run_query("SELECT * from mytable;")
```

### mongodb
Install: `uv add pymongo`
secrets.toml:
```toml
[mongo]
host = "$HOST"
port = "$PORT"
username = "$USERNAME"
password = "$PASSWORD"
```
Usage:
```python
import pymongo

@st.cache_resource
def init_connection():
    return pymongo.MongoClient(**st.secrets["mongo"])

client = init_connection()

@st.cache_data(ttl=600)
def get_data():
    db = client.mydb
    items = db.mycollection.find()
    items = list(items)
    return items

items = get_data()
```

### mysql
Install: `uv add mysqlclient sqlalchemy`
secrets.toml:
```toml
[connections.mysql]
dialect = "mysql"
host = "$HOST"
port = "$PORT"
database = "$DATABASE"
username = "$USERNAME"
password = "$PASSWORD"
```
Usage:
```python
conn = st.connection('mysql', type='sql')
df = conn.query('SELECT * from mytable;', ttl=600)
```

### postgresql
Install: `uv add psycopg2-binary sqlalchemy`
secrets.toml:
```toml
[connections.postgresql]
dialect = "postgresql"
host = "$HOST"
port = "$PORT"
database = "$DATABASE"
username = "$USERNAME"
password = "$PASSWORD"
```
Usage:
```python
conn = st.connection("postgresql", type="sql")
df = conn.query('SELECT * FROM mytable;', ttl="10m")
```

### snowflake
Install: `uv add snowflake-snowpark-python snowflake-connector-python`
secrets.toml:
```toml
[connections.snowflake]
account = "$ACCOUNT"
user = "$USER"
password = "$PASSWORD"  # or use private_key_file below
# private_key_file = "$PRIVATE_KEY_FILE"
role = "$ROLE"
warehouse = "$WAREHOUSE"
database = "$DATABASE"
schema = "$SCHEMA"
```
Usage:
```python
conn = st.connection("snowflake")
df = conn.query("SELECT * FROM mytable;", ttl="10m")
```

### tableau
Install: `uv add tableauserverclient`
secrets.toml:
```toml
[tableau]
token_name = "$TOKEN_NAME"
token_secret = "$TOKEN_SECRET"
server_url = "$SERVER_URL"
site_id = "$SITE_ID"
```
Usage:
```python
import tableauserverclient as TSC

tableau_auth = TSC.PersonalAccessTokenAuth(
    st.secrets["tableau"]["token_name"],
    st.secrets["tableau"]["token_secret"],
    st.secrets["tableau"]["site_id"],
)
server = TSC.Server(st.secrets["tableau"]["server_url"], use_server_version=True)

@st.cache_data(ttl=600)
def run_query():
    with server.auth.sign_in(tableau_auth):
        workbooks, pagination_item = server.workbooks.get()
        return [w.name for w in workbooks]

workbooks_names = run_query()
```

### tidb
Install: `uv add pymysql sqlalchemy`
secrets.toml:
```toml
[connections.tidb]
dialect = "mysql"
driver = "pymysql"
host = "$HOST"
port = "$PORT"
database = "$DATABASE"
username = "$USERNAME"
password = "$PASSWORD"
create_engine_kwargs = { connect_args = { ssl_verify_cert = true, ssl_verify_identity = true } }
```
Usage:
```python
conn = st.connection('tidb', type='sql')
df = conn.query('SELECT * from mytable;', ttl=600)
```

**Note**: TiDB Cloud requires SSL connections. Use PyMySQL instead of mysqlclient as it's a pure Python implementation that doesn't require system-level MySQL client libraries.

### tigergraph
Install: `uv add pyTigerGraph`
secrets.toml:
```toml
[tigergraph]
host = "$HOST"
username = "$USERNAME"
password = "$PASSWORD"  # For Cloud: this IS the GSQL secret
graphname = "$GRAPHNAME"
```

**Important**: TigerGraph has two deployment types with different authentication:
- **TigerGraph Cloud (Savannah)**: hostname contains `.tgcloud.io`, password field contains the GSQL secret
- **Self-hosted**: traditional username/password with secret creation

**Schema Access Pattern**:
- ❌ **DO NOT** use `conn.getSchema()` - it returns a list with unexpected structure
- ✅ **DO** use `conn.getVertexTypes()` and `conn.getEdgeTypes()` to get graph schema information
- Use `conn.getVertexCount(vertex_type)` and `conn.getEdgeCount(edge_type)` for statistics
- Use `conn.getVertices(vertex_type, limit=N)` to fetch sample vertices

Usage:
```python
import pyTigerGraph as tg
import streamlit as st

@st.cache_resource
def get_tigergraph_connection():
    """
    Initialize TigerGraph connection.
    Automatically detects Cloud vs self-hosted based on hostname.
    """
    config = st.secrets["tigergraph"]
    is_cloud = ".tgcloud.io" in config["host"]
    
    if is_cloud:
        # TigerGraph Cloud: password IS the GSQL secret
        conn = tg.TigerGraphConnection(
            host=config["host"],
            graphname=config["graphname"],
            username=config["username"],
            gsqlSecret=config["password"]  # Use gsqlSecret parameter for Cloud
        )
        # Get token using the secret
        token = conn.getToken(config["password"])
        conn.apiToken = token[0]
    else:
        # Self-hosted: use traditional authentication
        conn = tg.TigerGraphConnection(
            host=config["host"],
            graphname=config["graphname"],
            username=config["username"],
            password=config["password"]
        )
        # Try to create or use existing secret
        try:
            secrets = conn.getSecrets()
            if secrets:
                secret_alias = list(secrets.keys())[0]
                token = conn.getToken(secret_alias)
            else:
                secret = conn.createSecret()
                token = conn.getToken(secret)
            conn.apiToken = token[0]
        except Exception as e:
            # Handle cases where user lacks secret creation permissions
            st.warning(f"Could not authenticate: {e}")
    
    return conn

conn = get_tigergraph_connection()

# Get schema information (CORRECT METHOD)
vertex_types = conn.getVertexTypes()  # Returns list of vertex type names
edge_types = conn.getEdgeTypes()      # Returns list of edge type names

# Get statistics
@st.cache_data(ttl=600)
def get_vertex_stats(_conn):
    stats = {}
    for v_type in _conn.getVertexTypes():
        stats[v_type] = _conn.getVertexCount(v_type)
    return stats

# Get sample vertices
@st.cache_data(ttl=600)
def get_sample_vertices(_conn, v_type, limit=10):
    return _conn.getVertices(v_type, limit=limit)

# Query installed queries with caching
@st.cache_data(ttl=600)
def get_data(_conn, query_name):
    result = _conn.runInstalledQuery(query_name)
    return result

# Example usage
stats = get_vertex_stats(conn)
vertices = get_sample_vertices(conn, "User", limit=20)
data = get_data(conn, "queryName")
```

### openai
Install: `uv add openai`
secrets.toml:
```toml
[openai]
OPENAI_API_KEY = "$OPENAI_API_KEY"
```
Usage:
```python
from openai import OpenAI
client = OpenAI(api_key=st.secrets["openai"]["OPENAI_API_KEY"])
```

### anthropic
Install: `uv add anthropic`
secrets.toml:
```toml
[anthropic]
ANTHROPIC_API_KEY = "$ANTHROPIC_API_KEY"
```
Usage:
```python
from anthropic import Anthropic
client = Anthropic(api_key=st.secrets["anthropic"]["ANTHROPIC_API_KEY"])
```

### gemini
Install: `uv add google-generativeai`
secrets.toml:
```toml
[gemini]
GOOGLE_API_KEY = "$GOOGLE_API_KEY"
```
Usage:
```python
import google.generativeai as genai
genai.configure(api_key=st.secrets["gemini"]["GOOGLE_API_KEY"])
```

### gdrive (Google Drive - OAuth)
**Note**: This is an OAuth connector. Unlike other connectors, credentials are NOT stored in secrets.toml.
The deployment system automatically injects the necessary environment variables.

Install: `uv add google-api-python-client google-auth`
secrets.toml:
```toml
[gdrive]
connector_id = "$PREFIX_CONNECTOR_ID"  # Replace PREFIX with your connector's 6-char prefix (e.g., $MYDRIV_CONNECTOR_ID)
```

Usage:
```python
from secrets_utils import get_oauth_access_token
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
import streamlit as st

# Get connector ID from secrets
connector_id = st.secrets["gdrive"]["connector_id"]
# Fetch fresh access token from backend
access_token = get_oauth_access_token(connector_id)

# Create Google Drive client
creds = Credentials(token=access_token)
drive = build("drive", "v3", credentials=creds)

# List files
@st.cache_data(ttl=300)  # Cache for 5 minutes
def list_files():
    results = drive.files().list(pageSize=10).execute()
    return results.get("files", [])

files = list_files()
for file in files:
    st.write(f"{file['name']} ({file['id']})")
```

**Important**: The `get_oauth_access_token()` function fetches a fresh access token (~1 hour lifetime) from the Modal backend.
The `MEMEX_DEPLOYMENT_TOKEN` and `MEMEX_BACKEND_URL` environment variables are auto-injected when the deployment includes OAuth connectors.

# Streamlit API Notes
- Usage of `use_container_width` argument in `st.some_component(...)` is deprecated and this applies to all `st.` components. 
- For examples, instead of `st.button(..., use_container_width=True)`, use `st.button(..., width="stretch")`. Or instead of `st.dataframe(..., use_container_width=False)`, use `st.dataframe(..., width="content")`. Width must be either an integer (pixels), 'stretch', or 'content', never NONE.
