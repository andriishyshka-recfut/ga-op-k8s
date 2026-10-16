variable "RestoreBackupName" {
  description = "Full backup directory name to restore."
  type        = string
}

variable "RestoreRunId" {
  description = "Unique identifier for this restore invocation."
  type        = string
}

variable "RestoreDatabase" {
  description = "Database to restore; empty restores all databases."
  type        = string
  default     = ""
}
