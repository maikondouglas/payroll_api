# PayrollApi

API RESTful para gestão de folha de pagamento construída com Phoenix/Elixir.

## 🚀 Quick Start

### Desenvolvimento com Docker (Recomendado)
```bash
./setup.sh
```
ou
```bash
docker compose up -d
```

Acesse: http://localhost:4000/api/swagger

### Desenvolvimento Local
```bash
mix setup
mix phx.server
```

Acesse: http://localhost:4000

## 📚 Documentação

- **[Quick Start Guide](docs/QUICKSTART.md)** - Comece aqui! Guia de início rápido
- **[Docker Setup](docs/DOCKER_SETUP.md)** - Guia completo do ambiente Docker
- **[API Documentation](http://localhost:4000/api/swagger)** - Swagger UI (após iniciar o servidor)
- **[Development Guidelines](docs/AGENTS.md)** - Padrões e convenções do projeto

## 🛠️ Comandos Úteis

```bash
make help        # Ver todos os comandos disponíveis
make up          # Iniciar containers Docker
make logs        # Ver logs da aplicação
make test        # Rodar testes
make shell       # Abrir shell no container
```

## 🌐 Endpoints Principais

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| POST | `/api/v1/login` | Autenticação |
| GET | `/api/v1/me` | Dados do usuário |
| POST | `/api/v1/payroll/upload` | Upload CSV folha |
| GET | `/api/v1/my-payslips` | Listar contracheques |
| GET | `/api/v1/my-payslips/:id/download` | Download PDF |

## 📖 Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
