#!/bin/bash
# Script de onboarding para novos desenvolvedores
# Autor: DevOps Team
# Data: $(date +%Y-%m-%d)

set -e

# Cores para output
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║         PayrollAPI - Setup de Desenvolvimento              ║"
echo "║         Script de Onboarding Automático                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Verificar se Docker está instalado
echo -e "${CYAN}[1/6]${NC} Verificando Docker..."
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker não encontrado!${NC}"
    echo "Por favor, instale o Docker: https://docs.docker.com/get-docker/"
    exit 1
fi
echo -e "${GREEN}✓ Docker instalado: $(docker --version)${NC}"

# Verificar se Docker Compose está instalado
echo -e "${CYAN}[2/6]${NC} Verificando Docker Compose..."
if ! command -v docker compose &> /dev/null; then
    echo -e "${RED}✗ Docker Compose não encontrado!${NC}"
    echo "Por favor, instale o Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi
echo -e "${GREEN}✓ Docker Compose instalado: $(docker compose --version)${NC}"

# Verificar se Docker daemon está rodando
echo -e "${CYAN}[3/6]${NC} Verificando Docker daemon..."
if ! docker info &> /dev/null; then
    echo -e "${RED}✗ Docker daemon não está rodando!${NC}"
    echo "Por favor, inicie o Docker Desktop ou serviço Docker"
    exit 1
fi
echo -e "${GREEN}✓ Docker daemon está rodando${NC}"

# Parar containers existentes (se houver)
echo -e "${CYAN}[4/6]${NC} Limpando containers existentes..."
docker compose down &> /dev/null || true
echo -e "${GREEN}✓ Containers existentes removidos${NC}"

# Construir e subir os containers
echo -e "${CYAN}[5/6]${NC} Construindo e iniciando containers..."
echo -e "${YELLOW}Isso pode levar alguns minutos na primeira vez...${NC}"
if docker compose up -d --build; then
    echo -e "${GREEN}✓ Containers iniciados com sucesso${NC}"
else
    echo -e "${RED}✗ Erro ao iniciar containers${NC}"
    echo "Execute 'docker compose logs' para ver os logs de erro"
    exit 1
fi

# Aguardar serviços ficarem prontos
echo -e "${CYAN}[6/6]${NC} Aguardando serviços ficarem prontos..."
echo -n "Aguardando banco de dados"
for i in {1..30}; do
    if docker compose exec -T db pg_isready -U postgres &> /dev/null; then
        echo -e " ${GREEN}✓${NC}"
        break
    fi
    echo -n "."
    sleep 1
done

echo -n "Aguardando aplicação Phoenix"
for i in {1..60}; do
    if curl -s http://localhost:4000/api/openapi &> /dev/null; then
        echo -e " ${GREEN}✓${NC}"
        break
    fi
    echo -n "."
    sleep 1
done

# Executar seeds para criar usuário admin
echo -e "${CYAN}[BONUS]${NC} Criando usuário admin..."
if docker compose exec -T web mix run priv/repo/seeds.exs &> /dev/null; then
    echo -e "${GREEN}✓ Usuário admin criado com sucesso${NC}"
    echo -e "${YELLOW}  Email: admin@payroll.com | CPF: 00011122233 | Senha: password123${NC}"
else
    echo -e "${YELLOW}⚠ Seed já executado ou erro ao criar usuário admin${NC}"
fi

# Mensagem de sucesso
echo ""
echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                  🎉 Setup Completo! 🎉                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${CYAN}Serviços disponíveis:${NC}"
echo ""
echo -e "  📡 API:           ${GREEN}http://localhost:4000${NC}"
echo -e "  📝 Swagger UI:    ${GREEN}http://localhost:4000/api/swagger${NC}"
echo -e "  📄 OpenAPI Spec:  ${GREEN}http://localhost:4000/api/openapi${NC}"
echo -e "  🐘 PostgreSQL:    ${GREEN}localhost:5433${NC}"
echo ""
echo -e "${CYAN}Credenciais do Admin:${NC}"
echo ""
echo -e "  👤 Email:         ${GREEN}admin@payroll.com${NC}"
echo -e "  🔑 CPF (login):   ${GREEN}00011122233${NC}"
echo -e "  🔐 Senha:         ${GREEN}password123${NC}"
echo ""
echo -e "${CYAN}Comandos úteis:${NC}"
echo ""
echo -e "  make logs        ${YELLOW}# Ver logs da aplicação${NC}"
echo -e "  make shell       ${YELLOW}# Abrir shell no container${NC}"
echo -e "  make test        ${YELLOW}# Rodar testes${NC}"
echo -e "  make down        ${YELLOW}# Parar containers${NC}"
echo -e "  make help        ${YELLOW}# Ver todos os comandos${NC}"
echo ""
echo -e "${CYAN}Documentação completa:${NC} ${GREEN}docs/DOCKER_SETUP.md${NC}"
echo ""
echo -e "${YELLOW}Para ver os logs:${NC} docker compose logs -f web"
echo ""

# Abrir Swagger UI automaticamente (opcional)
read -p "Deseja abrir o Swagger UI no navegador? (s/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    xdg-open http://localhost:4000/api/swagger 2>/dev/null || \
    open http://localhost:4000/api/swagger 2>/dev/null || \
    echo "Por favor, abra manualmente: http://localhost:4000/api/swagger"
fi

echo ""
echo -e "${GREEN}Bom desenvolvimento! 🚀${NC}"
