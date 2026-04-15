# PPULSE HRMS — Security Documentation

## 1. Authentication

- **Password Hashing:** PBKDF2-SHA256 with 600,000 iterations (Django default)
- **JWT Tokens:** Access (30-day expiry) + Refresh tokens via SimpleJWT
- **Token Versioning:** Each user has `token_version`. Admin can increment it to invalidate all active sessions.
- **Account Lockout:** 50 failed attempts → 1-minute lockout (configurable)
- **SSO:** Microsoft Azure AD and Google OAuth2 integration

## 2. Face Verification Security

| Layer | Attack Defended | Method |
|-------|----------------|--------|
| LBP Texture | Printed photo | Histogram entropy analysis of skin micro-texture |
| FFT Moire | Screen replay | Frequency-domain detection of pixel grid patterns |
| Color Channel | Screen display | Blue-channel ratio analysis (screens vs natural skin) |
| Micro-Movement | Static photo | Cross-frame bbox displacement (2-15px = natural sway) |
| Saturation | Flat surfaces | Low saturation variance detection |
| Identity Gate | Impersonation | matched_employee_id must equal authenticated user_id |
| Margin Gate | Ambiguous match | Best score must beat #2 by >= 0.10 cosine similarity |

**Composite Score:** 60% texture signals + 40% movement → reject at >= 0.70

## 3. Data Protection (GDPR)

- **Export:** `/admin/users/{id}/gdpr-export` — full JSON export of employee data
- **Delete:** `/admin/users/{id}/gdpr-delete` — permanent data deletion with audit trail
- **Retention Policies:** Configurable per data type
- **Consent Ledger:** Tracks user consent for data processing

## 4. Audit Trail

Every security-relevant action is recorded in `api_auditlog`:
- Action type (e.g. `request_approved`, `face_punch_in_succeeded`, `face_punch_in_mismatch`)
- Actor (who performed), Target (who was affected)
- IP address and User-Agent
- Payload (JSON with metrics: confidence, elapsed_ms, etc.)

## 5. Network Security

- **IP Allowlisting:** Admin can restrict API access to approved IPs
- **CORS:** Strict origin validation
- **CSRF:** Django middleware enabled for web
- **HTTPS:** TLS 1.3 required in production

## 6. Access Control

| Endpoint Category | Employee | Manager | Admin |
|-------------------|----------|---------|-------|
| Own attendance | Yes | Yes | Yes |
| Team attendance | No | Own reports | All |
| Approve requests | No | Own reports | All |
| Audit logs | No | No | Yes |
| User management | No | No | Yes |
| System config | No | No | Yes |

---

**Classification:** Confidential
