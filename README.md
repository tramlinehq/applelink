# applelink
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)

API service that wraps over the App Store Connect API for commonly used patterns using [spaceship](spaceship.airforce/). Built with [Hanami::API](https://github.com/hanami/api).

### Running the service

```bash
bundle install
just start
```

To run linter,

```
just lint
```

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
