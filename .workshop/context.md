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
- **Deviate from the skill's code examples** (model names, SDK methods, parameters, patterns) — use them exactly as shown unless the user explicitly requests otherwise

**WHY:** Connector skills provide:
- Correct dependency installation commands
- Proper secret/environment variable names
- Tested connection patterns with **specific, verified values** (model names, API parameters)
- Security best practices

**Skills are authoritative, not suggestions.** The code examples, model names, and parameters in skills have been tested against the actual connectors. Copy them exactly. Do not substitute "better" alternatives — e.g., do not replace a skill's specified model with a different one you think is superior.
