# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 2.5.x   | :white_check_mark: |
| 2.0.x   | :white_check_mark: |
| < 2.0   | :x:                |

## Reporting a Vulnerability

We take the security of Git Mirror seriously. If you discover a security vulnerability, please follow these steps:

### 1. **DO NOT** create a public GitHub issue

Security vulnerabilities should be reported privately to maintain the safety of our users.

### 2. Email Security Team

Send an email to: **security@example.com** (please update with actual email)

Include the following information:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### 3. What to Expect

- **Initial Response**: Within 48 hours
- **Detailed Analysis**: Within 7 days
- **Resolution**: As quickly as possible, typically within 14 days
- **Public Disclosure**: After a patch is available

### 4. Security Advisory

Once the vulnerability is confirmed and patched, we will:
- Release a security patch
- Publish a security advisory on GitHub
- Credit the reporter (if desired)
- Update the CHANGELOG

## Security Best Practices for Users

### Authentication

**GitHub Token**:
- Use a Personal Access Token (PAT) with minimal required scopes
- Never commit tokens to version control
- Rotate tokens regularly
- Use environment variables: `export GITHUB_TOKEN="ghp_xxxxx"`

**SSH Keys**:
- Use strong key encryption (RSA 4096 or Ed25519)
- Protect private keys with passphrases
- Use separate keys for different purposes

### Git Operations

- Review repositories before cloning
- Use `--dry-run` mode to preview operations
- Set appropriate `--timeout` for network operations
- Monitor `--metrics` output for anomalies

### Network Security

- Clone over HTTPS by default
- Verify SSH fingerprints before initial connection
- Use VPN or secure network for sensitive repositories

### Input Validation

- Validate usernames and organization names
- Sanitize patterns in `--include` and `--exclude` options
- Use absolute paths for `--destination`

### Data Protection

- Secure backup storage locations
- Implement proper access controls
- Review and clean up old mirrors regularly

## Known Security Considerations

### Rate Limiting

- GitHub API rate limits: 60/hour (unauthenticated), 5000/hour (authenticated)
- Script includes automatic rate limit handling
- Monitor usage with `--metrics`

### Command Injection

- All user inputs are validated
- No `eval` usage in the codebase
- ShellCheck strict mode enabled (level "error")

### Sensitive Data Handling

- Tokens never logged or displayed
- SSH keys handled securely by SSH subsystem
- State files stored locally only

## Security Audits

Regular security audits are performed:
- **ShellCheck**: Automated static analysis (0 errors)
- **Manual Review**: Code review for security best practices
- **Dependency Check**: Regular updates of dependencies

## Responsible Disclosure

We follow responsible disclosure practices:
- Vulnerabilities remain private until patched
- Reporters are given credit (with permission)
- Full disclosure only after fix is available
- Coordinated disclosure when possible

## History

### 2025-01-27
- Initial security policy published
- Security audit completed (0 vulnerabilities found)
- ShellCheck strict mode enabled

## Contributing Security Improvements

Security improvements are welcome through pull requests. Please:
1. Follow the same process as regular contributions
2. Mark the PR with the `security` label
3. Provide detailed description of the security enhancement
4. Include tests for security scenarios

## Contact

For security-related questions or to report vulnerabilities:
- **Email**: security@example.com (please update)
- **Private Issue**: Use GitHub's private vulnerability reporting

## Resources

- [GitHub Security Policy](https://docs.github.com/en/code-security/getting-started/github-security-features)
- [OWASP Command Injection](https://owasp.org/www-community/attacks/Command_Injection)
- [Shell Security Best Practices](https://mywiki.wooledge.org/BashGuide)

---

**Last Updated**: 2025-01-27  
**Review Schedule**: Quarterly  
**Next Review**: 2025-04-27


