# =============================================================================
# ENERGY IoT PIPELINE - Makefile
# =============================================================================
# Usage: make <target>
# =============================================================================

.PHONY: help setup up down restart logs clean download-data \
        dbt-run dbt-test dbt-docs ge-run ge-docs \
        test lint format

# Default target
.DEFAULT_GOAL := help

# Colors for terminal output
BLUE := \033[34m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
NC := \033[0m # No Color

# =============================================================================
# HELP
# =============================================================================

help: ## Show this help message
	@echo ""
	@echo "$(BLUE)Energy IoT Pipeline$(NC) - Available commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""

# =============================================================================
# DOCKER INFRASTRUCTURE
# =============================================================================

setup: ## Initial setup (copy .env, create directories)
	@echo "$(BLUE)Setting up project...$(NC)"
	@cp -n .env.example .env 2>/dev/null || true
	@mkdir -p data/raw data/processed
	@touch data/raw/.gitkeep data/processed/.gitkeep
	@echo "$(GREEN)Setup complete!$(NC)"

up: ## Start all Docker services
	@echo "$(BLUE)Starting services...$(NC)"
	docker compose up -d
	@echo "$(GREEN)Services started!$(NC)"
	@echo ""
	@echo "Available services:"
	@echo "  - Superset:   http://localhost:8088"
	@echo "  - Airflow:    http://localhost:8080"
	@echo "  - Grafana:    http://localhost:3000"
	@echo "  - ClickHouse: http://localhost:8123"

down: ## Stop all Docker services
	@echo "$(YELLOW)Stopping services...$(NC)"
	docker compose down
	@echo "$(GREEN)Services stopped!$(NC)"

restart: down up ## Restart all services

logs: ## View logs from all services
	docker compose logs -f

logs-postgres: ## View PostgreSQL logs
	docker compose logs -f postgres

logs-airflow: ## View Airflow logs
	docker compose logs -f airflow-webserver

logs-superset: ## View Superset logs
	docker compose logs -f superset

ps: ## Show running containers
	docker compose ps

# =============================================================================
# DATA
# =============================================================================

download-data: ## Download Smart Meter dataset (requires Kaggle CLI)
	@echo "$(BLUE)Downloading Smart Meter dataset from Kaggle...$(NC)"
	@mkdir -p data/raw
	@echo "$(YELLOW)Note: Requires 'kaggle' CLI configured with API token$(NC)"
	@echo "$(YELLOW)See: https://www.kaggle.com/docs/api$(NC)"
	kaggle datasets download -d ziya07/smart-meter-electricity-consumption-dataset -p data/raw/
	@unzip -o data/raw/smart-meter-electricity-consumption-dataset.zip -d data/raw/
	@rm data/raw/smart-meter-electricity-consumption-dataset.zip
	@echo "$(GREEN)Data downloaded to data/raw/$(NC)"

download-data-manual: ## Instructions for manual download
	@echo "$(BLUE)Manual download instructions:$(NC)"
	@echo "1. Go to: https://www.kaggle.com/datasets/ziya07/smart-meter-electricity-consumption-dataset"
	@echo "2. Click 'Download' (requires Kaggle account)"
	@echo "3. Extract ZIP to data/raw/"
	@echo ""
	@echo "$(YELLOW)Or install Kaggle CLI:$(NC)"
	@echo "  pip install kaggle"
	@echo "  # Configure API token from kaggle.com/account"
	@echo "  make download-data"

ingest: ## Run data ingestion to PostgreSQL
	@echo "$(BLUE)Ingesting data to PostgreSQL...$(NC)"
	python src/ingestion/load_data.py
	@echo "$(GREEN)Ingestion complete!$(NC)"

# =============================================================================
# DBT
# =============================================================================

dbt-deps: ## Install dbt dependencies
	@echo "$(BLUE)Installing dbt packages...$(NC)"
	cd dbt && dbt deps

dbt-run: ## Run dbt models
	@echo "$(BLUE)Running dbt models...$(NC)"
	cd dbt && dbt run
	@echo "$(GREEN)dbt run complete!$(NC)"

dbt-test: ## Run dbt tests
	@echo "$(BLUE)Running dbt tests...$(NC)"
	cd dbt && dbt test
	@echo "$(GREEN)dbt tests complete!$(NC)"

dbt-build: ## Run dbt build (run + test)
	@echo "$(BLUE)Running dbt build...$(NC)"
	cd dbt && dbt build
	@echo "$(GREEN)dbt build complete!$(NC)"

dbt-docs: ## Generate and serve dbt documentation
	@echo "$(BLUE)Generating dbt docs...$(NC)"
	cd dbt && dbt docs generate && dbt docs serve --port 8001

dbt-clean: ## Clean dbt artifacts
	cd dbt && dbt clean

# =============================================================================
# GREAT EXPECTATIONS
# =============================================================================

ge-init: ## Initialize Great Expectations
	@echo "$(BLUE)Initializing Great Expectations...$(NC)"
	cd great_expectations && great_expectations init

ge-run: ## Run Great Expectations checkpoint
	@echo "$(BLUE)Running data quality checks...$(NC)"
	cd great_expectations && great_expectations checkpoint run energy_checkpoint
	@echo "$(GREEN)Data quality checks complete!$(NC)"

ge-docs: ## Build and open Great Expectations data docs
	@echo "$(BLUE)Building data docs...$(NC)"
	cd great_expectations && great_expectations docs build

# =============================================================================
# DEVELOPMENT
# =============================================================================

install: ## Install Python dependencies
	pip install -r requirements.txt

test: ## Run tests
	@echo "$(BLUE)Running tests...$(NC)"
	pytest tests/ -v
	@echo "$(GREEN)Tests complete!$(NC)"

lint: ## Run linters
	@echo "$(BLUE)Running linters...$(NC)"
	ruff check src/ tests/
	@echo "$(GREEN)Linting complete!$(NC)"

format: ## Format code
	@echo "$(BLUE)Formatting code...$(NC)"
	ruff format src/ tests/
	@echo "$(GREEN)Formatting complete!$(NC)"

# =============================================================================
# CLEANUP
# =============================================================================

clean: ## Remove generated files and caches
	@echo "$(YELLOW)Cleaning up...$(NC)"
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".ruff_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@echo "$(GREEN)Cleanup complete!$(NC)"

clean-docker: ## Remove Docker volumes and images
	@echo "$(RED)WARNING: This will remove all Docker volumes and images for this project$(NC)"
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ]
	docker compose down -v --rmi local
	@echo "$(GREEN)Docker cleanup complete!$(NC)"

clean-all: clean clean-docker ## Clean everything

# =============================================================================
# FULL PIPELINE
# =============================================================================

pipeline: ingest dbt-build ge-run ## Run full pipeline (ingest → dbt → GE)
	@echo "$(GREEN)Full pipeline complete!$(NC)"

demo: up download-data pipeline ## Full demo setup
	@echo ""
	@echo "$(GREEN)Demo ready!$(NC)"
	@echo "Open http://localhost:8088 for Superset dashboards"
