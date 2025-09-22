# Security Policy

## Supported Versions

We release patches for security vulnerabilities. Currently supported versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take the security of Asmbli seriously. If you believe you have found a security vulnerability, please report it to us as described below.

### Please do NOT:
- Open a public GitHub issue for security vulnerabilities
- Post about the vulnerability on social media

### Please DO:
- Email us at: security@asmbli.dev (or use the contact information in the repository)
- Include the word "SECURITY" in the subject line
- Provide detailed steps to reproduce the vulnerability
- Include the version of Asmbli affected
- Include any relevant logs or screenshots

### What to expect:
- You'll receive an acknowledgment within 48 hours
- We'll investigate and keep you updated on our progress
- We'll work on a fix and coordinate disclosure timing with you
- We'll publicly acknowledge your contribution (unless you prefer to remain anonymous)

## Security Best Practices for Users

### API Keys and Credentials
- Never commit API keys or credentials to the repository
- Use environment variables for all sensitive configuration
- Regularly rotate your API keys
- Use the minimum required permissions for API keys

### Configuration
- Always use `.env` files for local configuration
- Never share your `.env` files
- Review all configuration before deploying

### Dependencies
- Keep all dependencies up to date
- Regularly check for security advisories
- Run `npm audit` and `flutter pub outdated` periodically

### MCP Server Security
- Only use MCP servers from trusted sources
- Review MCP server permissions before granting access
- Limit MCP server access to necessary resources only
- Regularly audit your connected MCP servers

## Security Features

Asmbli includes several security features:

- **Secure credential storage**: Uses OS-native secure storage (Keychain on macOS)
- **API key encryption**: All stored credentials are encrypted
- **Permission system**: Granular permissions for MCP servers
- **OAuth 2.0 support**: Secure authentication for integrations
- **Input validation**: All user inputs are validated and sanitized

## Disclosure Policy

When we receive a security report, we will:

1. Confirm the problem and determine affected versions
2. Audit code to find similar problems
3. Prepare fixes for all supported versions
4. Release patches as soon as possible

## Comments on this Policy

If you have suggestions on how to improve this process, please submit a pull request or open an issue.

Thank you for helping keep Asmbli and our users safe!