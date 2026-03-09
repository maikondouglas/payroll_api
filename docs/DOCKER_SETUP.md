# PayrollAPI - Setup Docker para Desenvolvimento

Ambiente Docker completo para facilitar o onboarding de desenvolvedores.

## 📋 Pré-requisitos

- [Docker](https://docs.docker.com/get-docker/) instalado
- [Docker Compose](https://docs.docker.com/compose/install/) instalado

## 🚀 Início Rápido

### 1. Clonar o repositório
```bash
git clone <repository-url>
cd payroll_api
```

### 2. Subir os containers
```bash
docker compose up -d
```

Este comando irá:
- ✅ Baixar as imagens do PostgreSQL 15 e Elixir 1.16
- ✅ Construir a imagem da aplicação com Chromium instalado
- ✅ Criar o banco de dados automaticamente
- ✅ Instalar todas as dependências (`mix deps.get`)
- ✅ Rodar as migrations (`mix ecto.migrate`)
- ✅ Iniciar o servidor Phoenix na porta 4000

### 3. Verificar se está rodando
```bash
# Ver logs em tempo real
docker compose logs -f web

# Verificar se a API está respondendo
curl http://localhost:4000/api/openapi
```

### 4. Acessar a documentação Swagger
Abra no navegador: http://localhost:4000/api/swagger

## 🛠️ Comandos Úteis

### Gerenciar containers
```bash
# Subir os containers
docker compose up -d

# Ver logs
docker compose logs -f web

# Parar os containers
docker compose stop

# Parar e remover containers
docker compose down

# Rebuild da imagem (após alterar Dockerfile)
docker compose up -d --build
```

### Executar comandos dentro do container
```bash
# Abrir shell interativo no container
docker compose exec web bash

# Rodar migrations
docker compose exec web mix ecto.migrate

# Rodar testes
docker compose exec web mix test

# Criar migration
docker compose exec web mix ecto.gen.migration nome_da_migration

# Rodar seeds
docker compose exec web mix run priv/repo/seeds.exs

# Abrir IEx (console interativo)
docker compose exec web iex -S mix

# Formatar código
docker compose exec web mix format

# Rodar precommit checks
docker compose exec web mix precommit
```

### Reset completo do banco de dados
```bash
# Dentro do container
docker compose exec web mix ecto.reset

# Ou em uma linha
docker compose exec web sh -c "mix ecto.drop && mix ecto.create && mix ecto.migrate"
```

### Importar CSV de rubricas
```bash
# Copiar arquivo CSV para dentro do container
docker cp Rubricas_Janeiro_2026.csv payroll_api_web:/app/

# Executar import
docker compose exec web mix run -e "PayrollApi.Payroll.Importer.import_csv(\"Rubricas_Janeiro_2026.csv\", ~D[2026-01-01])"
```

## 🐛 Troubleshooting

### Container web não inicia
```bash
# Ver logs detalhados
docker compose logs web

# Rebuild forçado
docker compose down
docker compose up -d --build
```

### Problemas com banco de dados
```bash
# Resetar volume do PostgreSQL
docker compose down -v
docker compose up -d
```

### Porta já em uso
Se a porta 4000 ou 5432 já estiver em uso, edite o `docker compose.yml`:
```yaml
services:
  web:
    ports:
      - "4001:4000"  # <-- Mudar aqui
  db:
    ports:
      - "5433:5432"  # <-- Mudar aqui
```

### Live-reload não funciona
O live-reload do Phoenix funciona automaticamente através do `inotify-tools` instalado no container. Se não funcionar:

1. Verifique os logs: `docker compose logs -f web`
2. Rebuild: `docker compose up -d --build`

## 📁 Estrutura de Volumes

O `docker compose.yml` monta os seguintes volumes:

- `.:/app` - Todo o código fonte (para live-reload)
- `/app/_build` - Artifacts de compilação (isolados do host)
- `/app/deps` - Dependências Elixir (isoladas do host)
- `postgres_data` - Dados do PostgreSQL (persistentes)

## 🔧 Desenvolvimento Local vs Docker

O projeto suporta **ambos os modos**:

### Modo Local (sem Docker)
```bash
mix deps.get
mix ecto.setup
mix phx.server
```
Conecta em `localhost:5432`

### Modo Docker
```bash
docker compose up -d
```
Conecta em `db:5432` (hostname interno do Docker)

A configuração em `config/dev.exs` usa variáveis de ambiente para detectar automaticamente o modo.

## 🌐 Endpoints Disponíveis

Após subir a aplicação:

- **API Base**: http://localhost:4000
- **Swagger UI**: http://localhost:4000/api/swagger
- **OpenAPI Spec**: http://localhost:4000/api/openapi

### Endpoints Principais

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| POST | `/api/v1/login` | Autenticação (retorna JWT) |
| GET | `/api/v1/me` | Dados do usuário autenticado |
| POST | `/api/v1/payroll/upload` | Upload de CSV de rubricas |
| GET | `/api/v1/my-payslips` | Listar contracheques |
| GET | `/api/v1/my-payslips/:id` | Detalhes do contracheque |
| GET | `/api/v1/my-payslips/:id/download` | Download PDF |

## 🎯 Para o Dev Front-end

### 1. Subir ambiente
```bash
docker compose up -d
```

### 2. Testar autenticação
```bash
curl -X POST http://localhost:4000/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"cpf":"12345678901","password":"Muda@123"}'
```

### 3. Ver documentação completa
Acesse: http://localhost:4000/api/swagger

A documentação Swagger tem:
- ✅ Todos os endpoints documentados
- ✅ Schemas de request/response
- ✅ Try it out (testar direto no navegador)
- ✅ Exemplos de autenticação

## 📝 Notas Importantes

### Chromium para PDF
A aplicação usa `chromic_pdf` para gerar PDFs dos contracheques. O Chromium já está pré-instalado no container Docker, então a geração de PDFs funciona automaticamente.

### Mudanças no Código
Todas as mudanças no código são refletidas **imediatamente** no container graças ao volume mount e ao `inotify-tools`. Não é necessário rebuild!

### Persistência de Dados
Os dados do PostgreSQL são persistidos no volume `postgres_data`. Para limpar completamente:
```bash
docker compose down -v
```

## 🤝 Contribuindo

1. Faça suas alterações no código
2. Execute os testes: `docker compose exec web mix test`
3. Execute checagens: `docker compose exec web mix precommit`
4. Commit e push

---

**Dúvidas?** Consulte a [documentação do Phoenix](https://hexdocs.pm/phoenix/) ou abra uma issue.
