# mc-router Contract

## Purpose
This document fixes the initial mc-router integration contract for Phase 4 tasks `T-400` through `T-403`.

## Upstream Baseline
- Target project: `itzg/mc-router`
- Confirmation date: `2026-03-25`
- Primary source: upstream README on the default branch

## Confirmed Upstream Capabilities
- `mc-router` supports a JSON routes config file via `-routes-config` / `ROUTES_CONFIG`.
- The file shape is:

```json
{
  "default-server": null,
  "mappings": {
    "alpha.mc.hogehoge.fuga": "10.0.0.10:25565"
  }
}
```

- `default-server` may be `null` or omitted.
- Sending `SIGHUP` reloads the routes config from disk.
- Setting `-routes-config-watch` / `ROUTES_CONFIG_WATCH=true` makes mc-router watch the config file and reload automatically when the file changes.
- A REST API also exists:
  - `GET /routes`
  - `POST /routes`
  - `POST /defaultRoute`
  - `DELETE /routes/{serverAddress}`

## Locked Integration Decision For This App
- Rails uses the JSON routes config file as the authoritative publication output for the initial implementation.
- The config file stores the full desired route set, not incremental diffs.
- `default-server` stays `null`.
  This preserves the project requirement that unknown hostnames must be rejected.
- Each mapping key is the normalized public FQDN generated from `MinecraftServer#fqdn`.
- Each mapping value is the app-managed Minecraft container backend target in `container_name:25565` form.
- The active reload strategy is explicit `SIGHUP` after each Rails write:
  - Rails writes the full JSON config file
  - Rails resolves the compose-managed `mc-router` container by Docker labels
  - Rails sends `SIGHUP` so `mc-router` re-loads the file immediately
- `ROUTES_CONFIG_WATCH=true` remains an upstream capability, but it is not the active local strategy because bind-mounted file-watch pickup was unreliable in this environment.
- The compose-managed `mc-router` container should carry a stable label such as `app.kubos.dev/component=mc-router` so Rails can resolve it without depending on a generated container name.

## Rails Configuration Contract
- Local development writes routes to `tmp/mc-router/routes.json` under the app root.
- Production writes routes to `/rails/shared/mc-router/routes.json` so the Compose-managed Rails app and the long-lived `mc-router` sibling service share the same file.
- The active reload strategy is fixed to `docker_signal`.
- The active reload signal is fixed to `HUP`.
- Rails resolves the reload target by the fixed Docker label `app.kubos.dev/component=mc-router`.
- The REST API and command-based reload remain upstream capabilities, but they are not part of the supported app configuration contract.

## Implementation Notes
- `T-401` builds one route definition from `RouterRoute` + `MinecraftServer`.
- `T-402` renders the whole config as deterministic JSON with sorted mappings.
- `T-403` writes the config file and triggers reload according to the configured strategy.
- Disabled routes are omitted from the rendered config.
- Enabled routes without a resolved container-name backend are treated as invalid input and should fail fast.
