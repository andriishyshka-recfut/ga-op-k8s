# terraform-base


This will handle provisioning base service account/ VPC/ bucket for storing states / Bastion host, etc...

### Provisioning steps

Before first time run you have to create bucket for storing tf state and service account (to run terraform with)


1. Check `terrafrom-modules/common-vars` module and configure variables related to terraform-base.


2. Create Service account, Bucket and download key (project and bucket should be same as in provider.tf and bucket.tf)
```

export BUCKET_NAME=terraform-state-222

export GOOGLE_CREDENTIALS=~/terraform_key.json
export GOOGLE_REGION=us-east4
export GOOGLE_PROJECT=ardent-rarity-239115

rm ~/terraform_key.json
gcloud config set project ${PROJECT}
gsutil mb -c standard -l EUROPE-WEST3 gs://${BUCKET_NAME}/


gcloud iam service-accounts create terraform && sleep 30
gcloud iam service-accounts keys create ${GOOGLE_CREDENTIALS} --iam-account $(gcloud iam service-accounts list --format=json --filter="email ~ terraform" | jq '.[0].email' -j )
gcloud projects add-iam-policy-binding ${GOOGLE_PROJECT} --member "serviceAccount:$(gcloud iam service-accounts list --format=json --filter="email ~ terraform" | jq '.[0].email' -j )"  --role "roles/iam.serviceAccountAdmin"
gcloud projects add-iam-policy-binding ${GOOGLE_PROJECT} --member "serviceAccount:$(gcloud iam service-accounts list --format=json --filter="email ~ terraform" | jq '.[0].email' -j )"  --role "roles/iam.serviceAccountUser"
gcloud projects add-iam-policy-binding ${GOOGLE_PROJECT} --member "serviceAccount:$(gcloud iam service-accounts list --format=json --filter="email ~ terraform" | jq '.[0].email' -j )"  --role "roles/resourcemanager.projectIamAdmin"
gcloud projects add-iam-policy-binding ${GOOGLE_PROJECT} --member "serviceAccount:$(gcloud iam service-accounts list --format=json --filter="email ~ terraform" | jq '.[0].email' -j )"  --role "roles/storage.objectAdmin"
gcloud projects add-iam-policy-binding ${GOOGLE_PROJECT} --member "serviceAccount:$(gcloud iam service-accounts list --format=json --filter="email ~ terraform" | jq '.[0].email' -j )"  --role "roles/storage.admin"
gcloud projects add-iam-policy-binding ${GOOGLE_PROJECT} --member "serviceAccount:$(gcloud iam service-accounts list --format=json --filter="email ~ terraform" | jq '.[0].email' -j )"  --role "roles/serviceusage.serviceUsageAdmin"



```



3. Import bucket and Service account resources to continue manage them with tf
```
cd terraform-base

rm .terraform/ -rf && terraform init

terraform import  google_service_account.terraform projects/${PROJECT}/serviceAccounts/$(gcloud iam service-accounts list | awk '/terraform/{print $1}')
terraform import google_storage_bucket.terraform-state ${BUCKET_NAME}

```
4. Run Terraform:
```
terraform plan
terraform apply

```

5. Terraform should fail first time. You have to configure DNS record that pointing to bastion. Run to get details:
```
terraform refresh
```

6. Once DNS is propagated run terraform apply  to complete install one more time:
```
terraform apply
```
