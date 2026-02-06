**CRITICAL**: At the start of EVERY conversation, IMMEDIATELY invoke the `data-app-streamlit:data-app` skill using the Skill tool to load complete development guidelines.

## Data Source Implementation - CRITICAL

**When your task involves ANY connector/data source, invoke the relevant skill before writing any related code.**

1. Check available connectors in system prompt under "Available Connectors"
2. Invoke using: `Skill` tool with `connectors-streamlit:connector-{type}` format

**Examples:**
- Neon database → invoke `connectors-streamlit:connector-neon`
- PostgreSQL → invoke `connectors-streamlit:connector-postgresql`
- OpenAI → invoke `connectors-streamlit:connector-openai`

**DO NOT:**
- Manually implement database connections
- Write connector code before invoking the skill
- Guess at connection patterns

**WHY:** Connector skills provide:
- Correct dependency installation commands
- Proper secret/environment variable names
- Tested connection patterns
- Security best practices