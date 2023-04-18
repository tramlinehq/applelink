# applelink
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.0-4baaaa.svg)](CODE_OF_CONDUCT.md)

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

##### Success response
> ```json
> {
> "id": "1658845856",
> "name": "Ueno",
> "bundle_id": "com.tramline.ueno",
> "sku": "com.tramline.ueno"
> }
> ```

</details>

#### Fetch live info for an app

<details>
 <summary><code>GET</code> <code><b>/apple/connect/v1/apps/:bundle-id/current_status</b></code></summary>

##### Path parameters

> | name      |  type     | data type               | description                                                           |
> |-----------|-----------|-------------------------|-----------------------------------------------------------------------|
> | bundle-id | required  | string   | app's unique identifier  |

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

##### Success response
> ```json
> [
>   {
>     "name": "Big External Group",
>     "builds": [
>       {
>         "id": "da720570-cb6e-4b25-b82f-790045a6038e",
>         "build_number": "10001",
>         "status": "BETA_APPROVED",
>         "version_string": "1.46.0",
>         "release_date": "2023-04-17T07:03:01-07:00"
>       },
>       {
>         "id": "1c4d0eb3-5cec-47f2-a843-949b12a69784",
>         "build_number": "9103",
>         "status": "BETA_APPROVED",
>         "version_string": "1.45.0",
>         "release_date": "2023-04-13T00:09:38-07:00"
>       }
>     ]
>   },
>   {
>     "name": "Small External Group",
>     "builds": [
>       {
>         "id": "e1aa4795-0df2-4d76-b899-8ee95fb8589e",
>         "build_number": "10002",
>         "status": "BETA_APPROVED",
>         "version_string": "1.47.0",
>         "release_date": "2023-04-17T10:00:19-07:00"
>       },
>       {
>         "id": "da720570-cb6e-4b25-b82f-790045a6038e",
>         "build_number": "10001",
>         "status": "BETA_APPROVED",
>         "version_string": "1.46.0",
>         "release_date": "2023-04-17T07:03:01-07:00"
>       }
>     ]
>   },
>   {
>     "name": "production",
>     "builds": [
>       {
>         "id": "bf11d7a3-fe1c-4c71-acae-a9dc8af57907",
>         "version_string": "1.44.1",
>         "status": "READY_FOR_SALE",
>         "release_date": "2023-04-11T22:45:25-07:00",
>         "build_number": "9086"
>       }
>     ]
>   }
> ]
> ```

</details>

#### Fetch all beta groups for an app

<details>
 <summary><code>GET</code> <code><b>/apple/connect/v1/apps/:bundle-id/groups</b></code></summary>

##### Path parameters

> | name      |  type     | data type               | description                                                           |
> |-----------|-----------|-------------------------|-----------------------------------------------------------------------|
> | bundle-id | required  | string   | app's unique identifier  |

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

##### Success response
> ```json
> [
>   {
>     "name": "The Pledge",
>     "id": "fcacfdf7-db62-44af-a0cb-0676e17c251b",
>     "internal": true,
>     "testers": [
>       {
>         "name": "Akshay Gupta",
>         "email": "kitallis@gmail.com"
>       },
>       {
>         "name": "Pratul Kalia",
>         "email": "pratulkalia@gmail.com"
>       },
>       {
>         "name": "Nivedita Priyadarshini",
>         "email": "nid.mishra7@gmail.com"
>       }
>     ]
>   },
>   {
>     "name": "The Prestige",
>     "id": "2cd6be09-d959-4ed3-a4e7-db8cabbe44d0",
>     "internal": true,
>     "testers": [
>       {
>         "name": "Pratul Kalia",
>         "email": "pratulkalia@gmail.com"
>       }
>     ]
>   },
>   {
>     "name": "The Trick",
>     "id": "dab66de0-7af2-48ae-97af-cc8dfdbde51d",
>     "internal": true,
>     "testers": [
>       {
>         "name": "Nivedita Priyadarshini",
>         "email": "nid.mishra7@gmail.com"
>       }
>     ]
>   },
>   {
>     "name": "Big External Group",
>     "id": "3bc1ca3e-1d4f-4478-8f38-2dcae4dcbb69",
>     "internal": false,
>     "testers": []
>   },
>   {
>     "name": "Small External Group",
>     "id": "dc64b810-1157-4228-825b-eb9e95cc8fba",
>     "internal": false,
>     "testers": []
>   }
> ]
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

##### Example cURL

> ```bash
> curl -X GET \
> -H "Authorization: Bearer token" \
> -H "X-AppStoreConnect-Key-Id: key-id" \
> -H "X-AppStoreConnect-Issuer-Id: iss-id" \
> -H "X-AppStoreConnect-Token: token" \
> -H "Content-Type: application/json" \
> http://localhost:4000/apple/connect/v1/apps/com.tramline.app/builds/9018
> ```

##### Success response
> ```json
> {
> "id": "bc90d402-ed0c-4d05-887f-d300abc104e9",
> "build_number": "9018",
> "beta_internal_state": "IN_BETA_TESTING",
> "beta_external_state": "BETA_APPROVED",
> "uploaded_date": "2023-02-22T22:27:48-08:00",
> "expired": false,
> "processing_state": "VALID",
> "version_string": "1.5.0"
> }
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
> | group-id | required  | string   | beta group id (uuid)  |

##### Example cURL

> ```bash
> curl -X PATCH \
> -H "Authorization: Bearer token" \
> -H "X-AppStoreConnect-Key-Id: key-id" \
> -H "X-AppStoreConnect-Issuer-Id: iss-id" \
> -H "X-AppStoreConnect-Token: token" \
> -H "Content-Type: application/json" \
> http://localhost:4000/apple/connect/v1/apps/com.tramline.app/groups/3bc1ca3e-1d4f-4478-8f38-2dcae4dcbb69/add_build
> ```

</details>

#### Prepare a release for the app

<details>
 <summary><code>POST</code> <code><b>/apple/connect/v1/apps/:bundle_id/release/prepare</b></code></summary>

##### Path parameters

> | name      |  type     | data type               | description                                                           |
> |-----------|-----------|-------------------------|-----------------------------------------------------------------------|
> | bundle-id | required  | string   | app's unique identifier  |

##### JSON Parameters

> | name      |  type     | data type               | description                                                           |
> |-----------|-----------|-------------------------|-----------------------------------------------------------------------|
> | build-number | required  | integer   | build number  |
> | version | required  | string   | version name  |
> | is_phased_release | optional  | boolean   | flag to enable or disable phased release, defaults to false  |
> | metadata | required  | hash   | { "promotional_text": "this is the app store version promo text", "whats_new": "release notes"}  |

##### Example cURL

> ```bash
> curl -X POST \
> -H "Authorization: Bearer token" \
> -H "X-AppStoreConnect-Key-Id: key-id" \
> -H "X-AppStoreConnect-Issuer-Id: iss-id" \
> -H "X-AppStoreConnect-Token: token" \
> -H "Content-Type: application/json" \
> -d '{"build_number": 9018, "version": "1.6.2", "is_phased_release": true, "metadata": {"promotional_text": "app store version promo text", "whats_new": "release notes"} }' \
> http://localhost:4000/apple/connect/v1/apps/com.tramline.app/release/prepare
> ```

</details>

#### Submit a release for review

<details>
 <summary><code>PATCH</code> <code><b>/apple/connect/v1/apps/:bundle_id/release/submit</b></code></summary>

##### Path parameters

> | name      |  type     | data type               | description                                                           |
> |-----------|-----------|-------------------------|-----------------------------------------------------------------------|
> | bundle-id | required  | string   | app's unique identifier  |

##### JSON Parameters

> | name      |  type     | data type               | description                                                           |
> |-----------|-----------|-------------------------|-----------------------------------------------------------------------|
> | build-number | required  | integer   | build number  |

##### Example cURL

> ```bash
> curl -X PATCH \
> -H "Authorization: Bearer token" \
> -H "X-AppStoreConnect-Key-Id: key-id" \
> -H "X-AppStoreConnect-Issuer-Id: iss-id" \
> -H "X-AppStoreConnect-Token: token" \
> -H "Content-Type: application/json" \
> -d '{"build_number": 9018}' \
> http://localhost:4000/apple/connect/v1/apps/com.tramline.app/release/submit
> ```

</details>

#### Fetch the status of current inflight release

<details>
 <summary><code>GET</code> <code><b>/apple/connect/v1/apps/:bundle-id/release?build_number=:build-number</b></code></summary>

##### Path parameters

> | name      |  type     | data type               | description                                                           |
> |-----------|-----------|-------------------------|-----------------------------------------------------------------------|
> | bundle-id | required  | string   | app's unique identifier  |

##### Query parameters

> | name      |  type     | data type               | description                                                           |
> |-----------|-----------|-------------------------|-----------------------------------------------------------------------|
> | build-number | required  | integer   | build number  |

##### Example cURL

> ```bash
> curl -X GET \
> -H "Authorization: Bearer token" \
> -H "X-AppStoreConnect-Key-Id: key-id" \
> -H "X-AppStoreConnect-Issuer-Id: iss-id" \
> -H "X-AppStoreConnect-Token: token" \
> -H "Content-Type: application/json" \
> http://localhost:4000/apple/connect/v1/apps/com.tramline.app/release?build_number=500
> ```

##### Success response
> ```json
> {
>   "id": "bd31faa6-6a9a-4958-82de-d271ddc639a8",
>   "version_name": "1.8.0",
>   "app_store_state": "PENDING_DEVELOPER_RELEASE",
>   "release_type": "MANUAL",
>   "earliest_release_date": null,
>   "downloadable": true,
>   "created_date": "2023-02-25T03:02:46-08:00",
>   "build_number": "33417",
>   "build_id": "31aafef2-d5fb-45d4-9b02-f0ab5911c1b2",
>   "phased_release": {
>     "id": "bd31faa6-6a9a-4958-82de-d271ddc639a8",
>     "phased_release_state": "INACTIVE",
>     "start_date": "2023-02-28T06:38:39Z",
>     "total_pause_duration": 0,
>     "current_day_number": 0
>   },
>   "details": {
>     "id": "ef59d099-6154-4ccb-826b-3ffe6005ed59",
>     "description": "The true Yamanote line aural aesthetic.",
>     "locale": "en-US",
>     "keywords": "japanese, aural, subway",
>     "marketing_url": null,
>     "promotional_text": null,
>     "support_url": "http://tramline.app",
>     "whats_new": "We now have the total distance covered by each station across the line!"
>   }
> }
> ```

</details>


#### Start a release after review is approved

<details>
 <summary><code>PATCH</code> <code><b>/apple/connect/v1/apps/:bundle_id/release/start</b></code></summary>

##### Path parameters

> | name      |  type     | data type               | description                                                           |
> |-----------|-----------|-------------------------|-----------------------------------------------------------------------|
> | bundle-id | required  | string   | app's unique identifier  |

##### JSON Parameters

> | name      |  type     | data type               | description                                                           |
> |-----------|-----------|-------------------------|-----------------------------------------------------------------------|
> | build-number | required  | integer   | build number  |

##### Example cURL

> ```bash
> curl -X PATCH \
> -H "Authorization: Bearer token" \
> -H "X-AppStoreConnect-Key-Id: key-id" \
> -H "X-AppStoreConnect-Issuer-Id: iss-id" \
> -H "X-AppStoreConnect-Token: token" \
> -H "Content-Type: application/json" \
> -d '{"build_number": 9018}' \
> http://localhost:4000/apple/connect/v1/apps/com.tramline.app/release/start
> ```

</details>

#### Fetch the status of current live release

<details>
 <summary><code>GET</code> <code><b>/apple/connect/v1/apps/:bundle-id/release/live</b></code></summary>

##### Path parameters

> | name      |  type     | data type               | description                                                           |
> |-----------|-----------|-------------------------|-----------------------------------------------------------------------|
> | bundle-id | required  | string   | app's unique identifier  |

##### Example cURL

> ```bash
> curl -X GET \
> -H "Authorization: Bearer token" \
> -H "X-AppStoreConnect-Key-Id: key-id" \
> -H "X-AppStoreConnect-Issuer-Id: iss-id" \
> -H "X-AppStoreConnect-Token: token" \
> -H "Content-Type: application/json" \
> http://localhost:4000/apple/connect/v1/apps/com.tramline.app/release/live
> ```

##### Success response
> ```json
> {
>   "id": "bd31faa6-6a9a-4958-82de-d271ddc639a8",
>   "version_name": "1.8.0",
>   "app_store_state": "READY_FOR_SALE",
>   "release_type": "MANUAL",
>   "earliest_release_date": null,
>   "downloadable": true,
>   "created_date": "2023-02-25T03:02:46-08:00",
>   "build_number": "33417",
>   "build_id": "31aafef2-d5fb-45d4-9b02-f0ab5911c1b2",
>   "phased_release": {
>     "id": "bd31faa6-6a9a-4958-82de-d271ddc639a8",
>     "phased_release_state": "COMPLETE",
>     "start_date": "2023-02-28T06:38:39Z",
>     "total_pause_duration": 0,
>     "current_day_number": 4
>   },
>   "details": {
>     "id": "ef59d099-6154-4ccb-826b-3ffe6005ed59",
>     "description": "The true Yamanote line aural aesthetic.",
>     "locale": "en-US",
>     "keywords": "japanese, aural, subway",
>     "marketing_url": null,
>     "promotional_text": null,
>     "support_url": "http://tramline.app",
>     "whats_new": "We now have the total distance covered by each station across the line!"
>   }
> }
> ```


</details>

#### Pause the rollout of current live release

<details>
 <summary><code>PATCH</code> <code><b>/apple/connect/v1/apps/:bundle_id/release/live/rollout/pause</b></code></summary>

##### Path parameters

> | name      |  type     | data type               | description                                                           |
> |-----------|-----------|-------------------------|-----------------------------------------------------------------------|
> | bundle-id | required  | string   | app's unique identifier  |

##### Example cURL

> ```bash
> curl -X PATCH \
> -H "Authorization: Bearer token" \
> -H "X-AppStoreConnect-Key-Id: key-id" \
> -H "X-AppStoreConnect-Issuer-Id: iss-id" \
> -H "X-AppStoreConnect-Token: token" \
> -H "Content-Type: application/json" \
> http://localhost:4000/apple/connect/v1/apps/com.tramline.app/release/live/rollout/pause
> ```

</details>

#### Resume the rollout of current live release

<details>
 <summary><code>PATCH</code> <code><b>/apple/connect/v1/apps/:bundle_id/release/live/rollout/resume</b></code></summary>

##### Path parameters

> | name      |  type     | data type               | description                                                           |
> |-----------|-----------|-------------------------|-----------------------------------------------------------------------|
> | bundle-id | required  | string   | app's unique identifier  |

##### Example cURL

> ```bash
> curl -X PATCH \
> -H "Authorization: Bearer token" \
> -H "X-AppStoreConnect-Key-Id: key-id" \
> -H "X-AppStoreConnect-Issuer-Id: iss-id" \
> -H "X-AppStoreConnect-Token: token" \
> -H "Content-Type: application/json" \
> http://localhost:4000/apple/connect/v1/apps/com.tramline.app/release/live/rollout/resume
> ```

</details>

#### Fully release the current live release to all users

<details>
 <summary><code>PATCH</code> <code><b>/apple/connect/v1/apps/:bundle_id/release/live/rollout/complete</b></code></summary>

##### Path parameters

> | name      |  type     | data type               | description                                                           |
> |-----------|-----------|-------------------------|-----------------------------------------------------------------------|
> | bundle-id | required  | string   | app's unique identifier  |

##### Example cURL

> ```bash
> curl -X PATCH \
> -H "Authorization: Bearer token" \
> -H "X-AppStoreConnect-Key-Id: key-id" \
> -H "X-AppStoreConnect-Issuer-Id: iss-id" \
> -H "X-AppStoreConnect-Token: token" \
> -H "Content-Type: application/json" \
> http://localhost:4000/apple/connect/v1/apps/com.tramline.app/release/live/rollout/complete
> ```

</details>

#### Halt the current live release from distribution

<details>
 <summary><code>PATCH</code> <code><b>/apple/connect/v1/apps/:bundle_id/release/live/rollout/halt</b></code></summary>

##### Path parameters

> | name      |  type     | data type               | description                                                           |
> |-----------|-----------|-------------------------|-----------------------------------------------------------------------|
> | bundle-id | required  | string   | app's unique identifier  |

##### Example cURL

> ```bash
> curl -X PATCH \
> -H "Authorization: Bearer token" \
> -H "X-AppStoreConnect-Key-Id: key-id" \
> -H "X-AppStoreConnect-Issuer-Id: iss-id" \
> -H "X-AppStoreConnect-Token: token" \
> -H "Content-Type: application/json" \
> http://localhost:4000/apple/connect/v1/apps/com.tramline.app/release/live/rollout/halt
> ```

</details>
