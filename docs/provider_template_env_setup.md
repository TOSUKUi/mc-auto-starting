# Provisioning Template Environment Setup

## Purpose
This document defines the operational baseline for `T-304`.

`EXECUTION_PROVIDER_PROVISIONING_TEMPLATES` is the env entry that connects Rails-side `template_kind` values to real execution-provider provisioning settings.

Without this env, or with missing template keys, the create UI can no longer expose those templates, and real provisioning cannot succeed for them.

## Source Env

- Env key: `EXECUTION_PROVIDER_PROVISIONING_TEMPLATES`
- Format: JSON object
- Read path:
  - [config/initializers/execution_provider.rb](../config/initializers/execution_provider.rb)
- Consumed by:
  - [app/controllers/servers_controller.rb](../app/controllers/servers_controller.rb)
  - [app/services/execution_provider/provisioning_profile_resolver.rb](../app/services/execution_provider/provisioning_profile_resolver.rb)

## Contract Shape

Each top-level key is a Rails `template_kind`.

Minimum required fields per template:

- `owner_id`
- `node_id`
- `egg_id`
- `allocation_id`

Optional fields currently supported:

- `environment`
- `skip_scripts`
- `swap_mb`
- `io_weight`
- `cpu_limit`
- `cpu_pinning`
- `oom_killer_enabled`
- `allocation_limit`
- `backup_limit`
- `database_limit`

Rails automatically merges `minecraft_version` into `environment`, so it does not need to be duplicated unless a different provider-side keying scheme is added later.

## Baseline Example

The currently exposed create-form templates are:

- `fabric`
- `paper`
- `velocity`

If those options should remain visible in the UI, the env should include all three keys.

```json
{
  "fabric": {
    "owner_id": 40,
    "node_id": 2,
    "egg_id": 9,
    "allocation_id": 23,
    "environment": {
      "server_jarfile": "fabric-server-launch.jar"
    }
  },
  "paper": {
    "owner_id": 40,
    "node_id": 2,
    "egg_id": 7,
    "allocation_id": 21,
    "environment": {
      "server_jarfile": "paper.jar"
    }
  },
  "velocity": {
    "owner_id": 40,
    "node_id": 2,
    "egg_id": 8,
    "allocation_id": 22,
    "environment": {
      "server_jarfile": "velocity.jar"
    }
  }
}
```

## Operational Rules

- Do not expose a create-form template unless the matching top-level key exists in `EXECUTION_PROVIDER_PROVISIONING_TEMPLATES`.
- Keep `template_kind` names aligned between UI and env keys.
- Treat `allocation_id` as the selected default allocation for provider create requests.
- Treat `owner_id`, `node_id`, and `egg_id` as environment-specific operational data, not user input.

## Local Development Workflow

Before relying on real provisioning from the UI:

1. Set `EXECUTION_PROVIDER_PANEL_URL`.
2. Set `EXECUTION_PROVIDER_APPLICATION_API_KEY`.
3. Set `EXECUTION_PROVIDER_CLIENT_API_KEY`.
4. Set `EXECUTION_PROVIDER_PROVISIONING_TEMPLATES` with every template the UI should expose.
5. Restart the running Rails process so the initializer picks up the new env.
6. Open `/servers/new` and confirm the expected template options are visible.

If `/servers/new` shows the provider-template warning or disables the submit button, check `EXECUTION_PROVIDER_PROVISIONING_TEMPLATES` first.

## Failure Interpretation

- `execution provider provisioning template is not configured: <template>`
  - The env is missing the top-level template key.
- `execution provider provisioning template <template> is missing <field>`
  - The template exists, but one of the required fields is absent or blank.
- `execution provider panel_url is required`
  - Provider credentials or endpoint setup is still incomplete after template setup.

## Related Tasks

- `T-303`: provider config and initialization
- `T-304`: provisioning template env setup
- `T-501`: create job end-to-end
- `T-803`: acceptance verification that reflects configured provider templates
