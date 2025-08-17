# Environment Variables Setup

Configure these environment variables for your agent:

## GITHUB_PERSONAL_ACCESS_TOKEN
**GitHub Personal Access Token**
- Go to: https://github.com/settings/tokens
- Generate a new token (classic)
- Select required scopes: repo, read:org
- Copy the token

## POSTGRES_CONNECTION_STRING
**PostgreSQL Connection String**
- Format: postgresql://username:password@host:port/database
- Example: postgresql://user:pass@localhost:5432/mydb

## How to Set Environment Variables

### Windows
```cmd
set GITHUB_PERSONAL_ACCESS_TOKEN=your_value_here
```

### macOS/Linux
```bash
export GITHUB_PERSONAL_ACCESS_TOKEN=your_value_here
```

### ChatMCP Settings
You can also configure these directly in ChatMCP's settings interface.
