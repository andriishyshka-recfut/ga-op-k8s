### This will handle provisioning base service account/ VPC/ bucket for storing states / Bastion host, etc...


Before first time run(or after `terraform destroy` ) you have to create bucket for storing tf state and service account (to run terraform with)


1. Create Service account, Bucket and download key (project and bucket should be same as in rpovider.tf and bucket.tf)
```
export PROJECT=test-terraform2
export BUCKET_NAME=terraform-state-test112

rm ~/terraform_key.json
gcloud config set project ${PROJECT}
gsutil mb -c standard -l EUROPE-WEST3 gs://${BUCKET_NAME}/


gcloud iam service-accounts create terraform && sleep 30
gcloud iam service-accounts keys create ~/terraform_key.json --iam-account $(gcloud iam service-accounts list | awk '/terraform/{print $1}')
gcloud projects add-iam-policy-binding ${PROJECT} --member "serviceAccount:$(gcloud iam service-accounts list | awk '/terraform/{print $1}')"  --role "roles/iam.serviceAccountAdmin"
gcloud projects add-iam-policy-binding ${PROJECT} --member "serviceAccount:$(gcloud iam service-accounts list | awk '/terraform/{print $1}')"  --role "roles/iam.serviceAccountUser"
gcloud projects add-iam-policy-binding ${PROJECT} --member "serviceAccount:$(gcloud iam service-accounts list | awk '/terraform/{print $1}')"  --role "roles/resourcemanager.projectIamAdmin"
gcloud projects add-iam-policy-binding ${PROJECT} --member "serviceAccount:$(gcloud iam service-accounts list | awk '/terraform/{print $1}')"  --role "roles/storage.objectAdmin"
gcloud projects add-iam-policy-binding ${PROJECT} --member "serviceAccount:$(gcloud iam service-accounts list | awk '/terraform/{print $1}')"  --role "roles/storage.admin"
gcloud projects add-iam-policy-binding ${PROJECT} --member "serviceAccount:$(gcloud iam service-accounts list | awk '/terraform/{print $1}')"  --role "roles/serviceusage.serviceUsageAdmin"
export GOOGLE_CREDENTIALS=~/terraform_key.json


```


2. Import bucket and Service account resources to continue manage them with tf
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
