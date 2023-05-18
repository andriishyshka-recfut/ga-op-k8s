import json
import kopf
import kubernetes
import base64
import yaml
import os

JOB_TEMPLATE_YAML = "job_template.yaml"
JOB_NAME_PREFIX = os.environ.get('JOB_NAME_PREFIX') if os.environ.get('JOB_NAME_PREFIX') else "etl-"
SECRETS_PREFIX = os.environ.get('SECRETS_PREFIX') if os.environ.get('SECRETS_PREFIX') else "etl-"
MAIN_KEY = "etl-settings"
SCHEDULE_FIELD = "cron"
JOB_SUSPENDED_FIELD = "suspended"
TAG_FIELD = "etl_gitlab_tag"
SKIP_TAGS_FIELD = "skip-tags"
SECRET_PLACEHOLDER = "etl-clients-config"


@kopf.on.startup()
async def cleanup_old_jobs(logger, **kwargs):
    if "NAMESPACE" not in os.environ:
        return

    logger.info("Cleaning up cronjobs without secret")
    namespace = os.environ.get('NAMESPACE')
    try:
        kubernetes.config.load_incluster_config()  # cluster env vars
        logger.debug("configured in cluster with service account")
    except kubernetes.config.ConfigException:
        try:
            kubernetes.config.load_kube_config()  # developer's config files
            logger.debug("configured via kubeconfig file")
        except kubernetes.config.ConfigException:
            raise RuntimeError("Cannot authenticate neither in-cluster, nor via kubeconfig.")

    api = kubernetes.client.CoreV1Api()
    existing_secrets = api.list_namespaced_secret(namespace)

    api = kubernetes.client.BatchV1Api()
    existing_jobs = api.list_namespaced_cron_job(namespace)

    for job_name in [o.metadata.name for o in existing_jobs.items]:
        if job_name.startswith(JOB_NAME_PREFIX):
            secret_name = job_name.replace(JOB_NAME_PREFIX, SECRETS_PREFIX)
            if secret_name not in [o.metadata.name for o in existing_secrets.items]:
                api.delete_namespaced_cron_job(name=job_name, namespace=namespace)
                logger.info(f"Cronjob {job_name} has been deleted")


@kopf.on.create('secrets')
@kopf.on.update('secrets')
def process_secrets_update(spec, name, namespace, logger, **kwargs):
    try:
        if namespace != os.environ.get('NAMESPACE'):
            return

        if not name.startswith(SECRETS_PREFIX):
            logger.info(f"Secret {name} doesn't match pattern '{SECRETS_PREFIX}' - skipping")
            return

        api = kubernetes.client.CoreV1Api()
        secret = api.read_namespaced_secret(name, namespace).data

        if MAIN_KEY not in secret.keys():
            logger.info(f"Secret {name} doesn't contain ETL definition (field '{MAIN_KEY}') - skipping")

        secret_body = base64.b64decode(secret[MAIN_KEY]).decode('UTF-8')

        etl_settings = json.loads(secret_body)

        if SCHEDULE_FIELD not in etl_settings.keys():
            logger.info(
                f"Secret {name} doesn't contain cron schedule definition (field '{SCHEDULE_FIELD}') - skipping")
            return

        if JOB_SUSPENDED_FIELD not in etl_settings.keys():
            logger.info(
                f"Secret {name} doesn't contain job state declaration (field '{JOB_SUSPENDED_FIELD}') - skipping")
            return

        job_name = name.replace(SECRETS_PREFIX, JOB_NAME_PREFIX)

        with open(JOB_TEMPLATE_YAML, 'r') as file:
            job_cfg = yaml.safe_load(file)

            job_cfg["metadata"]["name"] = job_name
            job_cfg["metadata"]["namespace"] = namespace
            job_cfg["spec"]["schedule"] = etl_settings["cron"]
            projected_secrets = job_cfg["spec"]["jobTemplate"]["spec"]["template"]["spec"]["volumes"][0]["projected"]["sources"]

            secret_ref = next(ps for ps in projected_secrets
                               if str(ps["secret"]["name"]) == SECRET_PLACEHOLDER)
            secret_ref["secret"]["name"] = name


            is_suspended = etl_settings[JOB_SUSPENDED_FIELD].lower() == 'true'
            job_cfg["spec"]["suspend"] = is_suspended

            envs = job_cfg["spec"]["jobTemplate"]["spec"]["template"]["spec"]["containers"][0]["env"]

            if TAG_FIELD in etl_settings.keys():
                git_tag_env = next(je for je in envs
                                   if str(je["name"]) == 'GIT_TAG')
                git_tag_env["value"] = etl_settings[TAG_FIELD]
                logger.info(f"Cronjob {job_name} is set to be ran from custom tag/branch: {etl_settings[TAG_FIELD]}")

            if SKIP_TAGS_FIELD in etl_settings.keys():
                skip_tag_env = next(st for st in envs
                                   if str(st["name"]) == 'SKIP_TAGS')
                skip_tag_env["value"] = etl_settings[SKIP_TAGS_FIELD]
                logger.info(f"Cronjob {job_name} will skip the following tags: {etl_settings[SKIP_TAGS_FIELD]}")

            create_update_cronjob(job_cfg, job_name, namespace, logger)

    except Exception as e:
        logger.error(f"Failed to process event for secret {name}: {e}")


def create_update_cronjob(job_cfg, job_name, namespace, logger):
    job_body = kubernetes.client.V1CronJob(api_version=job_cfg["apiVersion"], kind="CronJob",
                                           metadata=job_cfg["metadata"], spec=job_cfg["spec"])
    api = kubernetes.client.BatchV1Api()
    existing_jobs = api.list_namespaced_cron_job(namespace)
    if job_name in [o.metadata.name for o in existing_jobs.items]:
        api.replace_namespaced_cron_job(name=job_name, namespace=namespace, body=job_body)
        logger.info(f"Cronjob {job_name} has been replaced with new definition")
    else:
        api.create_namespaced_cron_job(namespace=namespace, body=job_body)
        logger.info(f"Cronjob {job_name} has been created")


@kopf.on.delete('secrets', optional=True)
def delete_cronjob(spec, name, namespace, logger, **kwargs):
    try:
        if namespace != os.environ.get('NAMESPACE'):
            return
        api = kubernetes.client.BatchV1Api()
        job_name = JOB_NAME_PREFIX + name
        api.delete_namespaced_cron_job(name=job_name, namespace=namespace, propagation_policy='Background')
        logger.info(f"Cronjob {job_name} has been deleted")
    except Exception as e:
        logger.error(f"Failed to delete cronjob for secret {name} : {e}")
