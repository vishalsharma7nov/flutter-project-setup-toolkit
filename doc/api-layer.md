# API layer configuration

Configure how generated scaffolding and setup expect your app to talk to backends. Stored under `api` in `release-toolkit.config.json`.

## Protocols

| ID | Label |
|----|-------|
| `rest` | REST API (default) |
| `grpc` | gRPC |
| `graphql` | GraphQL |
| `websocket` | WebSocket |
| `sse` | Server-Sent Events |
| `firebase` | Firebase |
| `supabase` | Supabase |
| `local_only` | Local / offline only |
| `mixed` | Mixed backends |
| `external_sdk` | External vendor SDK (git dependency) |

Choose during Setup Studio step 4 or Feature Studio.

## REST configuration

```json
{
  "api": {
    "protocol": "rest",
    "rest_client": "dio",
    "use_retrofit": true,
    "codegen": {
      "json_serializable": true,
      "freezed": false
    },
    "local_cache": "none",
    "realtime": "none",
    "base_url_env_key": "API_BASE_URL",
    "auth_interceptor": false,
    "client_source": "pub_dev"
  }
}
```

| Field | Description |
|-------|-------------|
| `rest_client` | `dio` or `http` |
| `use_retrofit` | Scaffold for Retrofit-style clients |
| `codegen.json_serializable` | JSON serialization codegen hint |
| `codegen.freezed` | Freezed models hint |
| `local_cache` | `none`, `hive`, `isar`, `drift`, `shared_preferences` |
| `realtime` | `none`, `websocket`, `sse`, `firebase`, `supabase` |
| `base_url_env_key` | Env variable name for API base URL |
| `auth_interceptor` | Document auth interceptor pattern |
| `client_source` | `pub_dev` or `external_sdk` |

Setup wizard may add packages to `pubspec.yaml` based on protocol (e.g. `dio`, `connectivity_plus`, `retrofit`, `json_annotation`) when applying the plan.

## External vendor SDK

When `protocol` is `external_sdk`:

```json
{
  "api": {
    "protocol": "external_sdk",
    "client_source": "external_sdk",
    "external_sdk": {
      "package_name": "vendor_sdk",
      "source": "git",
      "git": {
        "url": "https://github.com/org/sdk.git",
        "ref": "main",
        "path": "packages/sdk"
      }
    }
  }
}
```

Setup Studio exposes git URL, ref, and monorepo path fields. The wizard adds a git dependency to your app's `pubspec.yaml`.

## Env integration

Point `base_url_env_key` at a key in your dart-define env files:

```env
API_BASE_URL=https://api.example.com
```

Build scripts pass env files via `--dart-define-from-file` (see [building.md](building.md)).

## Feature Studio

Feature Studio lets you change `api_protocol` and external SDK settings and save them back to config without re-running full setup (`POST /api/feature/save-config`).

## Future: contract codegen (Phase 7e backlog)

Planned optional scaffolds for OpenAPI, `.proto`, and GraphQL schema paths — config stubs and README sections only, no automatic codegen in the wizard.

## See also

- [Configuration](configuration.md)
- [Setup wizard](setup-wizard.md)
- [Feature scaffolding](feature-scaffolding.md)
