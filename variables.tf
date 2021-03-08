variable "project" {
  default = "vmstartstop"
}

variable "credential_file" {
  default = "vmstartstop-5684d5ebc0fe.json"
}

variable "pattern_stop" {
  default = "0 18 * * *"
}

variable "pattern_start" {
  default = "0 8 * * *"
}

variable "label_key" {
  default = "instance-scheduler"
}

variable "label_value" {
  default = "enabled"
}

variable "scheduler_function_bucket" {
  default = "auto_disable_enable_vm"
}

variable timezone {
  default = "CET"
}
