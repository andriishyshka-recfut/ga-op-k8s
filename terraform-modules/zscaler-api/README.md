# ZPA module


## Usage

Environment configs live in `clusters/<env>/07-zscaler-api/`.

- Run OpenTofu from the environment root, for example `clusters/sandbox/07-zscaler-api`. Use `otf` for sandbox and `otfprod` for production.
- `private_infra.json` defines ZPA connector groups, server groups, segment groups, provisioning keys, and application segments.
- `app_policies.json` defines access policies. Each policy lists SCIM groups allowed to access apps that reference that policy.

To add a new application entity (web domain, IP, CIDR range):

1. Add or reuse a policy in `app_policies.json`.
2. Add an application under `applications` in `private_infra.json`.
3. Set `domain`, `policies`, and only override default `segment_group`, `server_group`, or port ranges when needed.

To add a new policy:
1. Create a policy config in `app_policies.json`.
2. The policy can contains multiple user groups.
2. Update needed application with the new policy under `applications` in `private_infra.json`. The application can contains multiple policies.


## Development

- `config_schema.tf` is the validation schema for the configs. When changing `private_infra.json` or `app_policies.json` structure, make sure schema is also updated. New structure elements, which are not defined in schema, will be ignored. New schema entities, without being defined in the configs, will be set to `null`. 
