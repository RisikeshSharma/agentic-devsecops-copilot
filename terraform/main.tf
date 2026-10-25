resource "azurerm_resource_group" "copilot" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
  tags     = var.tags
}

# 1. Azure OpenAI Cognitive Account
resource "azurerm_cognitive_account" "openai" {
  name                = "cog-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.copilot.location
  resource_group_name = azurerm_resource_group.copilot.name
  kind                = "OpenAI"
  sku_name            = "S0"
  tags                = var.tags
}

# 2. Azure OpenAI Model Deployments with for_each iteration
resource "azurerm_cognitive_deployment" "models" {
  for_each = var.openai_models

  name                 = each.key
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = each.value.model_format
    name    = each.value.model_name
    version = each.value.model_version
  }

  scale {
    type     = each.value.scale_type
    capacity = each.value.capacity
  }
}

# 3. Log Analytics Workspace for Agent Telemetry
resource "azurerm_log_analytics_workspace" "logs" {
  name                = "log-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.copilot.location
  resource_group_name = azurerm_resource_group.copilot.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# 4. Azure Container Apps Managed Environment
resource "azurerm_container_app_environment" "env" {
  name                       = "cae-${var.project_name}-${var.environment}"
  location                   = azurerm_resource_group.copilot.location
  resource_group_name        = azurerm_resource_group.copilot.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
  tags                       = var.tags
}

# 5. MCP Server Container App with Dynamic env blocks
resource "azurerm_container_app" "mcp_host" {
  name                         = "app-mcp-server-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.copilot.name
  revision_mode                = "Single"
  tags                         = var.tags

  template {
    container {
      name   = "mcp-copilot-service"
      image  = "ghcr.io/risikeshsharma/agentic-devsecops-copilot:latest"
      cpu    = 1.0
      memory = "2Gi"

      dynamic "env" {
        for_each = var.container_env_vars
        content {
          name  = env.value.name
          value = env.value.value
        }
      }
    }
  }

  ingress {
    external_enabled = false
    target_port      = 8080
    transport        = "auto"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

# 6. Conditional Iteration: Qdrant Vector DB on Container Apps
resource "azurerm_container_app" "qdrant" {
  count = var.deploy_qdrant_vector_db ? 1 : 0

  name                         = "app-qdrant-vectordb-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.copilot.name
  revision_mode                = "Single"
  tags                         = var.tags

  template {
    container {
      name   = "qdrant"
      image  = "qdrant/qdrant:v1.9.0"
      cpu    = 1.0
      memory = "2Gi"
    }
  }

  ingress {
    external_enabled = false
    target_port      = 6333
    transport        = "auto"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}
