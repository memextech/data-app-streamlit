**CRITICAL**: At the start of EVERY conversation, IMMEDIATELY invoke the `data-app-streamlit:data-app` skill using the Skill tool to load complete development guidelines.

## Data Source Implementation - CRITICAL

**MANDATORY: When implementing ANY connector/data source:**

1. **ALWAYS invoke the connector skill FIRST** before writing any code
2. Check available connectors in system prompt under "Available Connectors"
3. Invoke using: `Skill` tool with `connectors-streamlit:connector-{type}` format

**Examples:**
- Neon database → invoke `connectors-streamlit:connector-neon` skill first
- PostgreSQL → invoke `connectors-streamlit:connector-postgresql` skill first
- OpenAI → invoke `connectors-streamlit:connector-openai` skill first

**DO NOT:**
- Manually implement database connections
- Write connector code before invoking the skill
- Guess at connection patterns

**WHY:** Connector skills provide:
- Correct dependency installation commands
- Proper secret/environment variable names
- Tested connection patterns
- Security best practices