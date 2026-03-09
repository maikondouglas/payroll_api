.PHONY: help up down restart logs shell test format precommit migrate setup reset

# Variável para comando Docker (pode ser sobrescrita se necessário usar sudo)
# Uso: make up DOCKER_CMD="sudo docker compose"
# Ou: export DOCKER_CMD="sudo docker compose" && make up
DOCKER_CMD ?= docker compose

# Cores para output
CYAN := \033[36m
RESET := \033[0m

help: ## Mostra esta mensagem de ajuda
	@echo "$(CYAN)Comandos disponíveis:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-15s$(RESET) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(CYAN)Nota:$(RESET) Se precisar de sudo, use: make COMANDO DOCKER_CMD=\"sudo docker compose\""

up: ## Sobe os containers em background
	$(DOCKER_CMD) up -d

down: ## Para e remove os containers
	$(DOCKER_CMD) down

restart: down up ## Reinicia os containers

logs: ## Mostra logs do container web
	$(DOCKER_CMD) logs -f web

logs-db: ## Mostra logs do container db
	$(DOCKER_CMD) logs -f db

shell: ## Abre shell bash no container web
	$(DOCKER_CMD) exec web bash

iex: ## Abre IEx (console Elixir interativo)
	$(DOCKER_CMD) exec web iex -S mix

test: ## Roda os testes
	$(DOCKER_CMD) exec web mix test

test-watch: ## Roda os testes em modo watch
	$(DOCKER_CMD) exec web mix test.watch

format: ## Formata o código Elixir
	$(DOCKER_CMD) exec web mix format

precommit: ## Roda checagens pre-commit (format check + tests)
	$(DOCKER_CMD) exec web mix precommit

migrate: ## Roda migrations pendentes
	$(DOCKER_CMD) exec web mix ecto.migrate

rollback: ## Reverte última migration
	$(DOCKER_CMD) exec web mix ecto.rollback

setup: ## Setup inicial do banco (create + migrate + seed)
	$(DOCKER_CMD) exec web mix ecto.setup

reset: ## Reset completo do banco
	$(DOCKER_CMD) exec web mix ecto.reset

routes: ## Mostra todas as rotas da aplicação
	$(DOCKER_CMD) exec web mix phx.routes

build: ## Rebuild da imagem Docker
	$(DOCKER_CMD) up -d --build

clean: ## Remove containers, volumes e imagens
	$(DOCKER_CMD) down -v --rmi local

ps: ## Lista containers rodando
	$(DOCKER_CMD) ps

deps: ## Atualiza dependências
	$(DOCKER_CMD) exec web mix deps.get

swagger: ## Abre Swagger UI no navegador
	@echo "Abrindo Swagger UI..."
	@xdg-open http://localhost:4000/api/swagger 2>/dev/null || open http://localhost:4000/api/swagger 2>/dev/null || echo "Acesse: http://localhost:4000/api/swagger"

health: ## Verifica health dos serviços
	@echo "$(CYAN)Verificando saúde dos serviços...$(RESET)"
	@curl -s http://localhost:4000/api/openapi > /dev/null && echo "✓ API: OK" || echo "✗ API: ERRO"
	@$(DOCKER_CMD) exec db pg_isready -U postgres > /dev/null && echo "✓ Database: OK" || echo "✗ Database: ERRO"
