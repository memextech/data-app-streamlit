**CRITICAL**: At the start of EVERY conversation, IMMEDIATELY invoke the `data-app-streamlit:data-app` skill using the Skill tool to load complete development guidelines.

---

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

## Skills - MANDATORY USAGE

**BLOCKING REQUIREMENT**: When implementing data connectors, you MUST use the appropriate skill as your FIRST action.

### Connector Skills (discover at runtime):
Before implementing a data connector, **check what skills are currently available** and use the matching connector skill for the requested data source.

### How to Use Skills:
1. When user requests a connector integration, IMMEDIATELY invoke the relevant skill
2. DO NOT write any implementation code before invoking the skill
3. Let the skill guide the implementation pattern

### Why Use Skills:
- Ensures standardized, tested patterns
- Includes proper error handling
- Uses correct secret management
- Follows best practices for each connector type
- Prevents manual implementation errors

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

**Important**: The `get_oauth_access_token()` function fetches a fresh access token (~1 hour lifetime) from the Modal backend.
The `MEMEX_DEPLOYMENT_TOKEN` and `MEMEX_BACKEND_URL` environment variables are auto-injected when the deployment includes OAuth connectors.

# Streamlit API Notes
- Usage of `use_container_width` argument in `st.some_component(...)` is deprecated and this applies to all `st.` components.
- For examples, instead of `st.button(..., use_container_width=True)`, use `st.button(..., width="stretch")`. Or instead of `st.dataframe(..., use_container_width=False)`, use `st.dataframe(..., width="content")`. Width must be either an integer (pixels), 'stretch', or 'content', never NONE.

# Streamlit Icons
NEVER use emojis in the streamlit apps you build unless the user explicitly asks for it.

ALWAYS default to using Streamlit's native support for Material icons.

Material icons can be used in buttons, alerts, expanders, and more.

## Example 1: Button with an icon
st.button("Click Me", icon=":material/mouse:")

## Example 2: A chat message with a user icon
with st.chat_message("User", avatar=":material/person:"):
    st.write("Hi!")

## Example 3: A chat message with a cognition_2 icon
with st.chat_message("Assistant", avatar=":material/cognition_2:"):
    st.write("Hello!")

# Streamlit Styling
All app styling is defined in `.streamlit/config.toml`

Do not edit or change those styles unless the user explicitly requests you do.

Do not define custom styling in `app.py` (or related) files unless the user explicitly requests you do.
