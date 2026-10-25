variable "environment" {
  description = "Target deployment environment."
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Primary Azure region."
  type        = string
  default     = "eastus"
}

variable "project_name" {
  description = "Project name prefix."
  type        = string
  default     = "agentic-copilot"
}

variable "openai_models" {
  description = "Map of OpenAI models deployed dynamically using for_each."
  type = map(object({
    model_format  = string
    model_name    = string
    model_version = string
    scale_type    = string
    capacity      = number
  }))
  default = {
    "gpt-4o" = {
      model_format  = "OpenAI"
      model_name    = "gpt-4o"
      model_version = "2024-05-13"
      scale_type    = "Standard"
      capacity      = 40
    }
    "text-embedding-3-small" = {
      model_format  = "OpenAI"
      model_name    = "text-embedding-3-small"
      model_version = "1"
      scale_type    = "Standard"
      capacity      = 80
    }
  }
}

variable "container_env_vars" {
  description = "List of environment variables iterated via dynamic block."
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    { name = "LOG_LEVEL", value = "INFO" },
    { name = "MCP_SERVER_PORT", value = "8080" },
    { name = "VECTOR_INDEX_NAME", value = "sre-incident-runbooks" }
  ]
}

variable "deploy_qdrant_vector_db" {
  description = "Conditional iteration flag to provision dedicated Qdrant vector database container."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Standard resource tags."
  type        = map(string)
  default = {
    Project   = "Agentic-DevSecOps-Copilot"
    ManagedBy = "Terraform"
    Owner     = "Rishikesh Sharma"
  }
}
