# 📚 Documentação Swagger - Payroll API v1

## Endpoints Documentados

### 🔐 Autenticação
| Método | Rota | Descrição |
|--------|------|-----------|
| POST | `/api/v1/login` | Autenticar usuário via CPF e senha |

**Request:**
```json
{
  "cpf": "12345678901",
  "password": "Senha@123"
}
```

**Response (200 OK):**
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

---

### 👤 Usuários
| Método | Rota | Autenticação | Descrição |
|--------|------|--------------|-----------|
| GET | `/api/v1/me` | ✅ Requerida | Obter dados do usuário autenticado |

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "name": "João Silva",
  "cpf": "12345678901",
  "role": "employee"
}
```

---

### 📊 Folha de Pagamento
| Método | Rota | Autenticação | Descrição |
|--------|------|--------------|-----------|
| POST | `/api/v1/payroll/upload` | ✅ Requerida | Importar folha de pagamento via CSV |

**Headers:**
```
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**Body (form-data):**
```
file: <arquivo.csv>
competence: 2026-01-01
```

**Response (200 OK):**
```json
{
  "message": "Importação concluída",
  "success": 85,
  "errors": 2,
  "details": [
    {
      "status": "success",
      "data": {
        "registration": "44",
        "cpf": "15634345472",
        "name": "ADRIANA LUCENA DA SILVA",
        "payslip_id": 123
      }
    }
  ]
}
```

---

### 📄 Contracheques
| Método | Rota | Autenticação | Descrição |
|--------|------|--------------|-----------|
| GET | `/api/v1/my-payslips` | ✅ Requerida | Listar contracheques do usuário |
| GET | `/api/v1/my-payslips/:id` | ✅ Requerida | Obter contracheque específico |

**Headers:**
```
Authorization: Bearer {token}
```

**Response GET /my-payslips (200 OK):**
```json
{
  "data": [
    {
      "id": 1,
      "competence": "2026-01-01",
      "base_salary": "3000.00",
      "net_salary": "2500.00",
      "employee_id": 1,
      "details": {
        "INSS Folha": "150.00",
        "Adicional Noturno": "200.00"
      },
      "inserted_at": "2026-03-08T10:30:00Z",
      "updated_at": "2026-03-08T10:30:00Z"
    }
  ]
}
```

**Response GET /my-payslips/:id (200 OK):**
```json
{
  "data": {
    "id": 1,
    "competence": "2026-01-01",
    "base_salary": "3000.00",
    "net_salary": "2500.00",
    "employee_id": 1,
    "details": {
      "INSS Folha": "150.00",
      "Adicional Noturno": "200.00",
      "IRRF Folha": "75.50"
    },
    "inserted_at": "2026-03-08T10:30:00Z",
    "updated_at": "2026-03-08T10:30:00Z"
  }
}
```

---

## 🔗 Acessar Swagger UI

```
http://localhost:4000/api/swagger
```

## 📋 Ver Especificação OpenAPI JSON

```
http://localhost:4000/api/openapi
```

---

## ✅ Status da Documentação

| Endpoint | Status | Schemas |
|----------|--------|---------|
| POST `/api/v1/login` | ✅ Documentado | LoginRequest, LoginResponse, ErrorResponse |
| GET `/api/v1/me` | ✅ Documentado | MeResponse, ErrorResponse |
| POST `/api/v1/payroll/upload` | ✅ Documentado | PayrollUploadRequest, PayrollUploadResponse, ImportDetail, ErrorResponse |
| GET `/api/v1/my-payslips` | ✅ Documentado | PayslipList, Payslip, ErrorResponse |
| GET `/api/v1/my-payslips/:id` | ✅ Documentado | Payslip, ErrorResponse |

---

## 📁 Arquivos Criados para Documentação

### Controllers (com anotações OpenApiSpex)
- `lib/payroll_api_web/controllers/v1/session_controller.ex`
- `lib/payroll_api_web/controllers/v1/user_controller.ex`
- `lib/payroll_api_web/controllers/v1/payroll_controller.ex`
- `lib/payroll_api_web/controllers/v1/my_payslip_controller.ex`

### Schemas (definições de tipos)
- `lib/payroll_api_web/schemas/login_request.ex`
- `lib/payroll_api_web/schemas/login_response.ex`
- `lib/payroll_api_web/schemas/error_response.ex`
- `lib/payroll_api_web/schemas/me_response.ex`
- `lib/payroll_api_web/schemas/user_data.ex`
- `lib/payroll_api_web/schemas/payslip.ex`
- `lib/payroll_api_web/schemas/payslip_list.ex`
- `lib/payroll_api_web/schemas/payroll_upload_request.ex`
- `lib/payroll_api_web/schemas/payroll_upload_response.ex`
- `lib/payroll_api_web/schemas/import_detail.ex`

### API Spec
- `lib/payroll_api_web/api_spec.ex`

---

## 🚀 Para Consumir a API

1. **Fazer Login:**
```bash
curl -X POST http://localhost:4000/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"cpf":"12345678901","password":"Muda@123"}'
```

2. **Usar Token em Requisições Autenticadas:**
```bash
curl -X GET http://localhost:4000/api/v1/me \
  -H "Authorization: Bearer {seu_token}"
```

3. **Visualizar Documentação Interativa:**
```
Abra no navegador: http://localhost:4000/api/swagger
```
