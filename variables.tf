variable "deployment_name" {
  default = "aksmig"
}

variable "location" {
  default = "eastus2"
}

variable "kubernetes_version" {
  default = "1.29"
}

variable "ollama_port" {
  default = 11434
}

variable "ollama_chart_version" {
  default = "0.52.0"
}

variable "gpu_operator_chart_version" {
  default = "v24.6.0"
}
