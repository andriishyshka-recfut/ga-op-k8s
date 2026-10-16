terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    vault = {
      source = "hashicorp/vault"
    }
  }
}

variable "ConnectionUrl" {
  description = "MongoDB URI containing Vault's {{username}} and {{password}} template fields."
  type        = string

  validation {
    condition = alltrue([
      for placeholder in ["{{username}}", "{{password}}"] :
      strcontains(var.ConnectionUrl, placeholder)
    ])

    error_message = "ConnectionUrl must contain {{username}} and {{password}}."
  }
}

variable "RootUsername" {
  description = "MongoDB user used by Vault to manage dynamic users."
  type        = string
  sensitive   = true
}

variable "RootPassword" {
  description = "Password of the MongoDB user used by Vault."
  type        = string
  sensitive   = true
}

variable "MongoHost" {
  description = "MongoDB host reachable from the Kubernetes reconciliation Job."
  type        = string

  validation {
    condition = trimspace(var.MongoHost) != ""

    error_message = "MongoHost must not be empty."
  }
}

variable "MongoPort" {
  description = "MongoDB port used by the Kubernetes reconciliation Job."
  type        = number
  default     = 27017

  validation {
    condition = (
      var.MongoPort == floor(var.MongoPort) &&
      var.MongoPort >= 1 &&
      var.MongoPort <= 65535
    )

    error_message = "MongoPort must be an integer between 1 and 65535."
  }
}

variable "MongoReplicaSet" {
  description = "MongoDB replica-set name used by the reconciliation Job to discover and connect to the primary."
  type        = string

  validation {
    condition = trimspace(var.MongoReplicaSet) != ""

    error_message = "MongoReplicaSet must not be empty."
  }
}

variable "KubernetesNamespace" {
  description = "Namespace in which to run the MongoDB custom-role reconciliation Job."
  type        = string
  default     = "mongo"
}

variable "RoleReconcilerImage" {
  description = "Container image containing mongosh for custom-role reconciliation."
  type        = string
  default     = "percona/percona-server-mongodb:6.0.9-7"
}

variable "MountPath" {
  description = "Path at which to mount the Vault Database Secrets Engine."
  type        = string
  default     = "mongodb"
}

variable "ConnectionName" {
  description = "Name of the MongoDB connection within the database secrets engine."
  type        = string
  default     = "mongodb"
}

variable "PasswordPolicyName" {
  description = "Name of the Vault password policy used to generate dynamic MongoDB credentials."
  type        = string
}

variable "PolicyNamePrefix" {
  description = "Prefix for the per-application Vault policies."
  type        = string
  default     = "mongodb"
}

variable "CustomRoleNamePrefix" {
  description = "Prefix for Terraform-managed custom MongoDB roles."
  type        = string
  default     = "vault"

  validation {
    condition = can(regex("^[A-Za-z0-9_-]+$", var.CustomRoleNamePrefix))

    error_message = "CustomRoleNamePrefix may contain only letters, digits, underscores, and hyphens."
  }
}

variable "VerifyConnection" {
  description = "Whether Vault verifies the MongoDB connection while configuring it."
  type        = bool
  default     = true
}
