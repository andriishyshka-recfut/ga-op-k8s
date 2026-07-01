# ZPA module


## Usage

Environment configs live in `clusters/<env>/07-zscaler-api/`.

- Run OpenTofu from the environment root, for example `clusters/sandbox/07-zscaler-api`. Use `otf` for sandbox and `otfprod` for production.
- `private_infra.json` defines ZPA connector groups, server groups, segment groups, provisioning keys, and application segments.
- `app_policies.json` defines access policies. Each policy lists SCIM groups and targets application keys through `apps` or segment group names through `groups`.

To add a new application entity (web domain, IP, CIDR range):

1. Add an application under `applications` in `private_infra.json`.
2. Set `domain`, and only override default `segment_group`, `server_group`, or port ranges when needed.
3. Add the application key to a policy `apps` list, or add its segment group to a policy `groups` list in `app_policies.json`.

To add a new policy:
1. Create a policy config in `app_policies.json`.
2. Set `scim_groups` to the existing ZPA SCIM groups that should get access.
3. Set `apps` for specific applications, or `groups` for segment groups.


## Development

- `config_schema.tf` is the validation schema for the configs. When changing `private_infra.json` or `app_policies.json` structure, make sure schema is also updated. New structure elements, which are not defined in schema, will be ignored. New schema entities, without being defined in the configs, will be set to `null`. 
