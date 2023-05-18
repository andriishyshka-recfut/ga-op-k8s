# ETL operator

Monitors and manages kubernetes CronJobs for running ETL ansible script.

Jobs are generated based on individual settings in corresponding Vault secret

Secrets are read from Vault using External Secrets CRD from path `secret/data/etl/clients`

Operator monitors only secrets that start with `etl-settings` prefix, ignoring any other secrets in given namespace

To on-board new client simply add corresponding secret to Vault and apply this terraform again


## Key fields

Behaviour of Cron Job can be adjusted by modifying these fields in Vault's secret:

| Field          | Function                                        |
|----------------|-------------------------------------------------|
| cron           | Cron formated field for specifying the schedule |
| suspended      | Enable/disable (suspend) Cron Job |
| etl_gitlab_tag | Read ansible from non-default branch or tag (default is `main`) |

Once changes are applied in Vault, operator will automatically apply them to corresponding Cron Job