# Chat-first product contract

- One universal chat composer for all user requests; never add a dedicated form for an app, API, connector, plugin or MCP tool.
- Replies, errors, confirmations and action results appear in the same chat transcript.
- Settings and integrations live on a separate screen, including models, plugins, MCP, APIs, connectors, permissions and privacy.
- Capabilities are implemented as invisible action adapters behind an intent router. New apps should not require new top-level UI.
- Before consequential external actions, show a clear confirmation with the exact intended action.
- The current router is deterministic offline keyword matching, **not an AI model**. BookMyShow can only be launched, not searched or scraped; never invent ticket availability.
- The existing backend and old task engine are not needed for the standalone chat MVP. Future extensions must preserve Android-first independence.
- Chat history is currently stored as local preferences, not encrypted; avoid entering secrets or sensitive personal information until secure storage is implemented.
