---
id: SYSREQ-003
title: OAuth2 Authentication
priority: high
type: feature
status: implemented
tags: [core, auth, oauth2, security]
scenarios:
  - id: SC-003-01
    name: Operate without credentials
    given: No OpenSky client ID or secret is configured
    when: A flight fetch is triggered
    then: The request is sent without an Authorization header (unauthenticated access)
  - id: SC-003-02
    name: Obtain access token with valid credentials
    given: Valid OpenSky client ID and secret are configured
    when: The first authenticated flight fetch is triggered
    then: An OAuth2 access token is obtained via client credentials flow
  - id: SC-003-03
    name: Cache and reuse access token
    given: A valid access token has been obtained and has not expired
    when: A subsequent flight fetch is triggered
    then: The cached token is reused without re-authenticating
  - id: SC-003-04
    name: Refresh expired token and retry
    given: The access token has expired
    when: A flight fetch returns a 401 Unauthorized response
    then: The token is refreshed and the request is retried automatically
  - id: SC-003-05
    name: Handle invalid credentials
    given: Invalid OpenSky client ID or secret are configured
    when: A flight fetch is triggered
    then: An unauthorized error is thrown
---

# SYSREQ-003: OAuth2 Authentication

## Description

The application supports OAuth2 client credentials flow to authenticate with the OpenSky Network API. When credentials are configured, access tokens are obtained, cached, and automatically refreshed on expiry. Without credentials, the app operates in unauthenticated mode (subject to OpenSky's anonymous rate limits).

## Source Files

- `UpThere/Services/FlightService.swift` — Token management and auth header injection
- `UpThere/Services/OpenSkyConfig.swift` — Credential storage and configuration

## Acceptance Criteria

1. Credentials are read from environment variables `OPENSKY_CLIENT_ID` and `OPENSKY_CLIENT_SECRET`
2. The app operates without credentials (unauthenticated mode)
3. When credentials are configured, OAuth2 client credentials flow is used:
   - Token endpoint: `https://auth.opensky-network.org/auth/realms/opensky-network/protocol/openid-connect/token`
   - Grant type: `client_credentials`
   - Content type: `application/x-www-form-urlencoded`
4. Access tokens are cached in memory and reused until expiry
5. Token expiry is calculated from the `expires_in` field with a 60-second safety margin
6. On 401 response, the token is cleared, a new token is obtained, and the request is retried
7. On 429 response, a `rateLimited` error is thrown
8. On auth failure, an `unauthorized` error is thrown

## Token Lifecycle

```
[Request needs token] → [Check cache: valid token?]
  → Yes → Use cached token
  → No  → [POST to auth endpoint] → [Cache token + expiry] → Use new token
```

On 401 response:
```
[401 received] → [Clear cached token] → [Obtain new token] → [Retry request]
```

## Configuration

| Field | Source | Description |
|-------|--------|-------------|
| `clientId` | `OPENSKY_CLIENT_ID` env var | OpenSky API client ID |
| `clientSecret` | `OPENSKY_CLIENT_SECRET` env var | OpenSky API client secret |
| `baseURL` | Hardcoded | `https://opensky-network.org/api` |
| `authURL` | Hardcoded | OpenSky OAuth2 token endpoint |

`isConfigured` returns `true` only when both `clientId` and `clientSecret` are non-empty strings.

## Edge Cases

- Token is cached with a 60-second safety margin before actual expiry
- If token refresh fails after a 401, the original 401 error is propagated
- Auth errors are logged with status code but without exposing credentials
- The `refreshToken()` method validates that both clientId and clientSecret are present before attempting authentication
