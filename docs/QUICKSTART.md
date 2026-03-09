# 🚀 Quick Start - PayrollAPI

> **Para novos desenvolvedores**: Este é o guia de início mais rápido!

## ⚡ Setup em 1 minuto

### Método 1: Script Automático (Recomendado)
```bash
./setup.sh
```

✅ Verifica dependências  
✅ Constrói os containers  
✅ Inicia todos os serviços  
✅ Aguarda tudo ficar pronto  
✅ Mostra URLs úteis  

### Método 2: Manual
```bash
docker compose up -d
```

Aguarde ~2 minutos e acesse: http://localhost:4000/api/swagger

## 🎯 Testando a API

### 1. Login (obter JWT token)
```bash
curl -X POST http://localhost:4000/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{
    "cpf": "12345678901",
    "password": "Muda@123"
  }'
```

**Resposta:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "name": "João Silva",
    "cpf": "12345678901",
    "role": "employee"
  }
}
```

### 2. Listar contracheques
```bash
curl -X GET http://localhost:4000/api/v1/my-payslips \
  -H "Authorization: Bearer SEU_TOKEN_AQUI"
```

### 3. Download PDF de contracheque
```bash
curl -X GET http://localhost:4000/api/v1/my-payslips/1/download \
  -H "Authorization: Bearer SEU_TOKEN_AQUI" \
  --output contracheque.pdf
```

## 📝 Comandos Úteis Diários

```bash
# Ver logs em tempo real
make logs

# Rodar testes
make test

# Abrir shell no container
make shell

# Ver todos os comandos
make help

# Parar tudo
make down
```

## 🌐 URLs Importantes

| Serviço | URL | Descrição |
|---------|-----|-----------|
| **Swagger UI** | http://localhost:4000/api/swagger | Interface interativa da API |
| **OpenAPI Spec** | http://localhost:4000/api/openapi | Especificação OpenAPI JSON |
| **PostgreSQL** | localhost:5432 | Banco de dados |

### Credenciais do Banco (dev)
- **Host**: localhost
- **Port**: 5432
- **Database**: payroll_api_dev
- **User**: postgres
- **Password**: postgres

## 🐛 Troubleshooting Rápido

### Porta já em uso?
```bash
# Verificar qual processo está na porta 4000
lsof -ti:4000

# Mudar porta no docker compose.yml para 4001:4000
```

### Container não inicia?
```bash
docker compose logs web
docker compose down && docker compose up -d --build
```

### Reset completo?
```bash
docker compose down -v
docker compose up -d
```

## 📚 Documentação Completa

- [DOCKER_SETUP.md](DOCKER_SETUP.md) - Guia completo do Docker
- [README.md](../README.md) - Documentação geral do projeto
- [AGENTS.md](AGENTS.md) - Guidelines do projeto

## 💡 Dicas

1. **Swagger UI** é seu melhor amigo - use para testar endpoints
2. **Live reload** está ativo - só salvar o código e atualiza
3. **Logs** são essenciais - sempre rode `make logs` quando algo der errado
4. **Makefile** tem todos os comandos que você precisa - rode `make help`

---

**Dúvidas?** Pergunte no canal do time ou abra uma issue! 🤝
