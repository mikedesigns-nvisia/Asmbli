# MCP Credentials Setup Guide

Quick setup guide for real MCP server authentication. Get your agents working with actual services!

## 🔑 1. API Keys (Most Common)

### GitHub Personal Access Token
**Get it**: https://github.com/settings/tokens
1. Click **Generate new token** → **Classic**
2. Set **Name**: `AgentEngine MCP`
3. Set **Expiration**: `90 days` (or as needed)
4. **Scopes**: Select `repo`, `read:org`, `user:email`
5. Click **Generate token**
6. Copy the token → Add to your `.env` file as `GITHUB_PERSONAL_ACCESS_TOKEN`

### Linear API Key
**Get it**: https://linear.app/settings/api
1. Go to **Settings** → **API**
2. Click **Create key**
3. Set **Label**: `AgentEngine`
4. Copy the key → Add to `.env` as `LINEAR_API_KEY`

### Brave Search API
**Get it**: https://api.search.brave.com/
1. Sign up for Brave Search API
2. Get your API key
3. Add to `.env` as `BRAVE_API_KEY`

## 🔗 2. Service Tokens (Pre-Generated)

### Slack Bot Token
**Setup**: https://api.slack.com/apps
1. **Create New App** → **From scratch**
2. Set **App Name**: `AgentEngine Bot`
3. Choose your workspace
4. Go to **OAuth & Permissions**
5. Add **Bot Token Scopes**: `channels:read`, `chat:write`, `files:read`, `users:read`
6. **Install to Workspace**
7. Copy **Bot User OAuth Token** → Add to `.env` as `SLACK_BOT_TOKEN`

### Notion Integration Token
**Setup**: https://www.notion.so/my-integrations
1. **Create new integration**
2. Set **Name**: `AgentEngine`
3. Choose workspace
4. Set **Type**: `Internal integration`
5. **Capabilities**: Read, Update, Insert content
6. Copy **Integration Token** → Add to `.env` as `NOTION_API_TOKEN`
7. **Share databases** with your integration in Notion

## 🗄️ 3. Database Connections

### PostgreSQL
```env
POSTGRES_CONNECTION_STRING=postgresql://username:password@localhost:5432/database_name
```

### SQLite
```env
SQLITE_DATABASE_PATH=/path/to/your/database.db
```

## ☁️ 4. Cloud Providers

### AWS
**Get credentials**: https://console.aws.amazon.com/iam/
1. Go to **IAM** → **Users** → Create user
2. Attach **AmazonS3ReadOnlyAccess** (or as needed)
3. Create **Access key**
4. Add to `.env`:
```env
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_DEFAULT_REGION=us-east-1
```

## 🚀 Quick Start

1. **Copy the template** from `.env` in your app folder
2. **Replace placeholders** with your real credentials
3. **Restart the app** to load new credentials
4. **Go to Tools → Catalog → Configure** to test connections

## ✅ Testing Your Setup

1. Open **AgentEngine** 
2. Go to **Tools** → **Catalog**
3. Click **Configure** on any MCP server
4. You should see **Configured** status for services you set up

## 🔒 Security Notes

- **Never commit** real credentials to git
- **Use environment variables** for production
- **Rotate keys regularly** 
- **Only grant minimum required permissions**

## 📞 Need Help?

Each service has documentation:
- **GitHub**: https://docs.github.com/en/authentication
- **Linear**: https://developers.linear.app/docs
- **Slack**: https://api.slack.com/authentication
- **Notion**: https://developers.notion.com/docs/authorization
- **AWS**: https://docs.aws.amazon.com/IAM/latest/UserGuide/

## 🎯 What You Get

With these credentials, your agents can:
- **GitHub**: Read repos, create issues, manage PRs
- **Linear**: Create tasks, track projects, manage teams  
- **Slack**: Send messages, read channels, manage files
- **Notion**: Read/write pages, query databases
- **Databases**: Query and analyze data
- **AWS**: Access S3, EC2, Lambda services

Start with **GitHub** and **Linear** - they're the easiest and most useful for development workflows!