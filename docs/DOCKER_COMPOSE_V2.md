# 🔄 Migração: docker-compose → docker compose

## O que mudou?

Este projeto foi atualizado para usar o **Docker Compose V2**, que está integrado ao Docker CLI.

### Antes (Docker Compose V1)
```bash
docker-compose up -d
docker-compose logs -f
docker-compose down
```

### Agora (Docker Compose V2)
```bash
docker compose up -d    # Sem hífen!
docker compose logs -f
docker compose down
```

## Por que a mudança?

- ✅ **Docker Compose V2** é mais rápido e eficiente
- ✅ Integrado nativamente ao Docker CLI (sem instalação separada)
- ✅ Melhor compatibilidade com Docker Desktop
- ✅ Comando padrão para Docker 20.10+ e Docker Desktop

## Verificando sua versão

```bash
docker compose version
```

**Saída esperada:**
```
Docker Compose version v2.x.x
```

## E se eu tiver apenas docker-compose?

Se você ainda tem o Docker Compose V1 (comando `docker-compose` com hífen):

### Opção 1: Atualizar para Docker Compose V2 (Recomendado)

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install docker-compose-plugin
```

**Docker Desktop:**
- Atualize para a versão mais recente
- Docker Compose V2 vem integrado

### Opção 2: Criar alias temporário

Se não puder atualizar agora, crie um alias:

```bash
# No seu ~/.bashrc ou ~/.zshrc
alias 'docker compose'='docker-compose'
```

Depois execute:
```bash
source ~/.bashrc  # ou ~/.zshrc
```

## Compatibilidade

Todos os arquivos do projeto foram atualizados:
- ✅ `Makefile` - Todos os comandos
- ✅ `setup.sh` - Script de onboarding
- ✅ `README.md` - Documentação principal
- ✅ `docs/QUICKSTART.md` - Guia rápido
- ✅ `docs/DOCKER_SETUP.md` - Guia detalhado

## Arquivos que não mudaram

- `docker-compose.yml` - O nome do arquivo permanece o mesmo
- `docker-compose.override.yml` - Ainda usa este nome
- `.gitignore` - Referências aos nomes de arquivo mantidas

## Testando

```bash
# Deve funcionar sem erros
make help
make up
docker compose ps
```

## Mais informações

- [Docker Compose V2 Documentation](https://docs.docker.com/compose/cli-command/)
- [Migrating to Docker Compose V2](https://docs.docker.com/compose/migrate/)

---

**Data da migração:** 8 de março de 2026  
**Versão do Docker Compose:** v2.x+
