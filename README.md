# applelink
[![License](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/tramlinehq/applelink/blob/master/LICENSE)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.0-4baaaa.svg)](code_of_conduct.md) 

APIs that wrap over the App Store Connect API for commonly used patterns using [spaceship](https://spaceship.airforce).

Built with [Hanami::API](https://github.com/hanami/api).

## Development

### Running

```bash
bundle install
just start
just lint # run lint
```

### Auth token

All APIs (except ping) are secured by JWT auth. Please use standard authorization header:
```
Authorization: Bearer <TRAMLINE_ISSUED_TOKEN>
```

## API

One can also use [requests](test/requests) in [restclient-mode](https://github.com/pashky/restclient.el) to interactively play around with the entire API including fetching and refreshing tokens.

### Headers

| Name | Description |
|------|-------------|
| `Authorization` | Bearer token signed by tramline |
| `Content-Type` | Most endpoints expect `application/json` |
| `X-AppStoreConnect-Key-Id` | App Store Connect key id acquired from the portal |
| `X-AppStoreConnect-Issuer-Id` | App Store Connect issuer id acquired from the portal |
| `X-AppStoreConnect-Token` | App Store Connect expirable JWT signed using the key-id and issuer-id |

#### Fetch metadata for an App

<details>
 <summary><code>GET</code> <code><b>/apple/connect/v1/apps/:bundle-id</b></code></summary>

##### Path parameters

> | name      |  type     | data type               | description                                                           |
> |-----------|-----------|-------------------------|-----------------------------------------------------------------------|
> | bundle-id | required  | string   | app's unique identifier  |


##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `201`         | `text/plain;charset=UTF-8`        | `Configuration created successfully`                                |
> | `400`         | `application/json`                | `{"code":"400","message":"Bad Request"}`                            |
> | `405`         | `text/html;charset=utf-8`         | None                                                                |

##### Example cURL

> ```bash
> curl -X GET \
> -H "Authorization: Bearer token" \
> -H "X-AppStoreConnect-Key-Id: key-id" \
> -H "X-AppStoreConnect-Issuer-Id: iss-id" \
> -H "X-AppStoreConnect-Token: token" \
> -H "Content-Type: application/json" \
> http://localhost:4000/apple/connect/v1/apps/com.tramline.app
> ```

</details>

#### Fetch live info for an app

<details>
 <summary><code>GET</code> <code><b>/apple/connect/v1/apps/:bundle-id/current_status</b></code></summary>

##### Path parameters

> | name      |  type     | data type               | description                                                           |
> |-----------|-----------|-------------------------|-----------------------------------------------------------------------|
> | bundle-id | required  | string   | app's unique identifier  |

##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `201`         | `text/plain;charset=UTF-8`        | `Configuration created successfully`                                |
> | `400`         | `application/json`                | `{"code":"400","message":"Bad Request"}`                            |
> | `405`         | `text/html;charset=utf-8`         | None                                                                |

##### Example cURL

> ```bash
> curl -X GET \
> -H "Authorization: Bearer token" \
> -H "X-AppStoreConnect-Key-Id: key-id" \
> -H "X-AppStoreConnect-Issuer-Id: iss-id" \
> -H "X-AppStoreConnect-Token: token" \
> -H "Content-Type: application/json" \
> http://localhost:4000/apple/connect/v1/apps/:bundle-id/current_status
> ```

</details>

#### Fetch all beta groups for an app

<details>
 <summary><code>GET</code> <code><b>/apple/connect/v1/apps/:bundle-id/groups</b></code></summary>

##### Path parameters

> | name      |  type     | data type               | description                                                           |
> |-----------|-----------|-------------------------|-----------------------------------------------------------------------|
> | bundle-id | required  | string   | app's unique identifier  |

##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `201`         | `text/plain;charset=UTF-8`        | `Configuration created successfully`                                |
> | `400`         | `application/json`                | `{"code":"400","message":"Bad Request"}`                            |
> | `405`         | `text/html;charset=utf-8`         | None                                                                |

##### Example cURL

> ```bash
> curl -X GET \
> -H "Authorization: Bearer token" \
> -H "X-AppStoreConnect-Key-Id: key-id" \
> -H "X-AppStoreConnect-Issuer-Id: iss-id" \
> -H "X-AppStoreConnect-Token: token" \
> -H "Content-Type: application/json" \
> http://localhost:4000/apple/connect/v1/apps/com.tramline.app/groups
> ```

</details>

#### Fetch a single build for an app

<details>
 <summary><code>GET</code> <code><b>/apple/connect/v1/apps/:bundle-id/builds/:build-number</b></code></summary>

##### Path parameters

> | name      |  type     | data type               | description                                                           |
> |-----------|-----------|-------------------------|-----------------------------------------------------------------------|
> | bundle-id | required  | string   | app's unique identifier  |
> | build-number | required  | integer   | build number  |

##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `201`         | `text/plain;charset=UTF-8`        | `Configuration created successfully`                                |
> | `400`         | `application/json`                | `{"code":"400","message":"Bad Request"}`                            |
> | `405`         | `text/html;charset=utf-8`         | None                                                                |

##### Example cURL

> ```bash
> curl -X GET \
> -H "Authorization: Bearer token" \
> -H "X-AppStoreConnect-Key-Id: key-id" \
> -H "X-AppStoreConnect-Issuer-Id: iss-id" \
> -H "X-AppStoreConnect-Token: token" \
> -H "Content-Type: application/json" \
> http://localhost:4000/apple/connect/v1/apps/com.tramline.app/builds/500
> ```

</details>

#### Assign a build to a beta group

<details>
 <summary><code>PATCH</code> <code><b>/apple/connect/v1/apps/:bundle_id/groups/:group-id/add_build</b></code></summary>

##### Path parameters

> | name      |  type     | data type               | description                                                           |
> |-----------|-----------|-------------------------|-----------------------------------------------------------------------|
> | bundle-id | required  | string   | app's unique identifier  |
> | build-number | required  | integer   | build number  |

##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `201`         | `text/plain;charset=UTF-8`        | `Configuration created successfully`                                |
> | `400`         | `application/json`                | `{"code":"400","message":"Bad Request"}`                            |
> | `405`         | `text/html;charset=utf-8`         | None                                                                |

##### Example cURL

> ```bash
> curl -X PATCH \
> -H "Authorization: Bearer token" \
> -H "X-AppStoreConnect-Key-Id: key-id" \
> -H "X-AppStoreConnect-Issuer-Id: iss-id" \
> -H "X-AppStoreConnect-Token: token" \
> -H "Content-Type: application/json" \
> http://localhost:4000/apple/connect/v1/apps/com.tramline.app/groups/group-123/add_build
> ```

</details>
