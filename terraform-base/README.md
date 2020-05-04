### This will handle provisioning base service account/ VPC/ bucket for storing states / Bastion host, etc...


Before first time run you have to create bucket for storing tf state and service account (to run terraform with)

1. Create Service account and download key
```
gcloud iam service-accounts create terraform
gcloud iam service-accounts keys create ~/terraform_key.json --iam-account $(gcloud iam service-accounts list | awk '/terraform/{print $1}')
gcloud projects add-iam-policy-binding terraform-k8s-spin-up --member "serviceAccount:$(gcloud iam service-accounts list | awk '/terraform/{print $1}')"  --role "roles/iam.serviceAccountAdmin"
gcloud projects add-iam-policy-binding terraform-k8s-spin-up --member "serviceAccount:$(gcloud iam service-accounts list | awk '/terraform/{print $1}')"  --role "roles/iam.serviceAccountUser"
gcloud projects add-iam-policy-binding terraform-k8s-spin-up --member "serviceAccount:$(gcloud iam service-accounts list | awk '/terraform/{print $1}')"  --role "roles/resourcemanager.projectIamAdmin"
gcloud projects add-iam-policy-binding terraform-k8s-spin-up --member "serviceAccount:$(gcloud iam service-accounts list | awk '/terraform/{print $1}')"  --role "roles/storage.objectAdmin"
gcloud projects add-iam-policy-binding terraform-k8s-spin-up --member "serviceAccount:$(gcloud iam service-accounts list | awk '/terraform/{print $1}')"  --role "roles/storage.admin"
export GOOGLE_CREDENTIALS=~/terraform_key.json


```

2. Create Bucket (Bucket name should be unique)

```

gsutil mb -c standard -l EUROPE-WEST3 gs://terraform-state-test111/

```

3. Import bucket and Service account resources to continue manage them with tf
```
cd terraform-base
terraform init

terraform import  google_service_account.terraform projects/terraform-k8s-spin-up/serviceAccounts/$(gcloud iam service-accounts list | awk '/terraform/{print $1}')
terraform import google_storage_bucket.terraform-state terraform-state-test111

```
