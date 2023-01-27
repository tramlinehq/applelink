# applelink

## Running the service

```bash
bundle install
bundle exec rackup
```

## Usage

This API is a wrapper over Apple's App Store API.

### Auth token

All APIs (except ping) are secured by JWT auth. Please use standard authorization header:
```
Authorization: Bearer <TRAMLINE_ISSUED_TOKEN>
```

### Additional Headers

```
X-AppStoreConnect-Key-Id: KEY_ID
X-AppStoreConnect-Issuer-Id: ISSUER_ID
X-AppStoreConnect-Token: JWT_TOKEN
``` 
