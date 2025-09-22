# OAuth Setup Guide for Asmbli

This guide walks you through setting up real OAuth applications with each provider to enable the authentication handshake.

## 🔐 Prerequisites

1. You need accounts with each service you want to integrate
2. Admin/developer access to create OAuth applications
3. A deployed version of your app or a development server with a stable URL

## 📋 Required OAuth Applications

### 1. **Microsoft** (Azure AD/Entra ID)
**Portal**: https://portal.azure.com → App registrations

**Steps**:
1. Go to **Azure Portal** → **App registrations** → **New registration**
2. Set **Name**: `Asmbli Desktop App`
3. Set **Supported account types**: `Accounts in any organizational directory and personal Microsoft accounts`
4. Set **Redirect URI**: 
   - Type: `Public client/native (mobile & desktop)`
   - URI: `http://localhost:3000/oauth/microsoft/callback`
5. Click **Register**
6. Note the **Application (client) ID** → This is your `MICROSOFT_CLIENT_ID`
7. Go to **Certificates & secrets** → **New client secret**
8. Add description, set expiry, click **Add**
9. Copy the **Value** → This is your `MICROSOFT_CLIENT_SECRET`
10. Go to **API permissions** → **Add a permission**
11. Add: `Microsoft Graph` → `Delegated permissions` → `User.Read`, `Files.Read`, `Mail.Read`

**Required Scopes**: `User.Read Files.Read Mail.Read`

---

### 2. **GitHub**
**Portal**: https://github.com/settings/developers

**Steps**:
1. Go to **Settings** → **Developer settings** → **OAuth Apps** → **New OAuth App**
2. Set **Application name**: `Asmbli Desktop`
3. Set **Homepage URL**: `https://your-domain.com` (or local development URL)
4. Set **Authorization callback URL**: `http://localhost:3000/oauth/github/callback`
5. Click **Register application**
6. Note the **Client ID** → This is your `GITHUB_CLIENT_ID`
7. Click **Generate a new client secret**
8. Copy the secret → This is your `GITHUB_CLIENT_SECRET`

**Required Scopes**: `user:email repo read:org`

---

### 3. **Slack**
**Portal**: https://api.slack.com/apps

**Steps**:
1. Go to **Your Apps** → **Create New App** → **From scratch**
2. Set **App Name**: `Asmbli`
3. Choose your **Slack workspace**
4. Click **Create App**
5. Go to **OAuth & Permissions**
6. Add **Redirect URLs**: `http://localhost:3000/oauth/slack/callback`
7. Scroll to **Scopes** → **Bot Token Scopes**
8. Add: `channels:read`, `chat:write`, `files:read`, `users:read`
9. Go to **Basic Information**
10. Note **Client ID** → This is your `SLACK_CLIENT_ID`
11. Note **Client Secret** → This is your `SLACK_CLIENT_SECRET`

**Required Scopes**: `channels:read chat:write files:read users:read`

---

### 4. **Linear**
**Portal**: https://linear.app/settings/api

**Steps**:
1. Go to **Settings** → **API** → **Personal API keys** → **Create key**
2. Set **Label**: `Asmbli Integration`
3. Set **Scopes**: Select appropriate permissions
4. Click **Create key**
5. Copy the key → This is your `LINEAR_API_KEY`

**Note**: Linear primarily uses API keys, not OAuth. Update your config accordingly.

---

### 5. **Notion**
**Portal**: https://www.notion.so/my-integrations

**Steps**:
1. Go to **My integrations** → **Create new integration**
2. Set **Name**: `Asmbli`
3. Set **Associated workspace**: Choose your workspace
4. Set **Type**: `Public integration`
5. Click **Submit**
6. Note **OAuth client ID** → This is your `NOTION_CLIENT_ID`
7. Note **OAuth client secret** → This is your `NOTION_CLIENT_SECRET`
8. Set **Redirect URIs**: `http://localhost:3000/oauth/notion/callback`
9. Set **Capabilities**: `Read content`, `Update content`, `Insert content`

**Required Scopes**: `read_content update_content insert_content`

---

## 🔧 Configuration

After creating all OAuth applications, update your `.env` file:

\`\`\`env
# Real OAuth Credentials (replace the placeholder values)
GITHUB_CLIENT_ID=your_actual_github_client_id
GITHUB_CLIENT_SECRET=your_actual_github_client_secret
GITHUB_REDIRECT_URI=http://localhost:3000/oauth/github/callback

SLACK_CLIENT_ID=your_actual_slack_client_id
SLACK_CLIENT_SECRET=your_actual_slack_client_secret
SLACK_REDIRECT_URI=http://localhost:3000/oauth/slack/callback

LINEAR_CLIENT_ID=your_actual_linear_client_id
LINEAR_CLIENT_SECRET=your_actual_linear_client_secret
LINEAR_REDIRECT_URI=http://localhost:3000/oauth/linear/callback

NOTION_CLIENT_ID=your_actual_notion_client_id
NOTION_CLIENT_SECRET=your_actual_notion_client_secret
NOTION_REDIRECT_URI=http://localhost:3000/oauth/notion/callback

MICROSOFT_CLIENT_ID=your_actual_microsoft_client_id
MICROSOFT_CLIENT_SECRET=your_actual_microsoft_client_secret
MICROSOFT_REDIRECT_URI=http://localhost:3000/oauth/microsoft/callback
\`\`\`

## 🔒 Security Best Practices

1. **Never commit real secrets to git** - Use environment variables
2. **Use HTTPS in production** - Update redirect URLs for production deployment
3. **Rotate secrets regularly** - Most providers support secret rotation
4. **Limit scopes** - Only request permissions you actually need
5. **Monitor usage** - Most providers have dashboards to monitor API usage

## 🚀 Production Deployment

For production, update redirect URLs to your actual domain:
- Development: `http://localhost:3000/oauth/{provider}/callback`
- Production: `https://yourdomain.com/oauth/{provider}/callback`

## 🧪 Testing

1. Start your Asmbli app
2. Go to **Settings** → **OAuth Connections**
3. Click **Connect** on any provider
4. You should be redirected to the provider's authorization page
5. After authorization, you'll be redirected back with a valid token

## 📞 Support

Each provider has comprehensive documentation:
- **Microsoft**: https://docs.microsoft.com/en-us/azure/active-directory/develop/
- **GitHub**: https://docs.github.com/en/developers/apps
- **Slack**: https://api.slack.com/authentication/oauth-v2
- **Linear**: https://developers.linear.app/docs/oauth
- **Notion**: https://developers.notion.com/docs/authorization