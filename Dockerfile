# Dockerfile para desenvolvimento - PayrollAPI
# Usa Debian para facilitar instalação do Chromium (necessário para chromic_pdf)

FROM elixir:1.16.0

# Instalar dependências do sistema
# - inotify-tools: necessário para file watching e live-reload do Phoenix
# - chromium e fontes: necessários para a biblioteca chromic_pdf gerar PDFs
# - build-essential, git: ferramentas de desenvolvimento
RUN apt-get update && apt-get install -y \
    inotify-tools \
    chromium \
    chromium-driver \
    fonts-liberation \
    fonts-noto-color-emoji \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Instalar Hex e Rebar (gerenciadores de pacotes Elixir/Erlang)
RUN mix local.hex --force && \
    mix local.rebar --force

# Definir diretório de trabalho
WORKDIR /app

# Expor porta do Phoenix
EXPOSE 4000

# O comando será definido no docker-compose.yml
# Isso permite mais flexibilidade durante o desenvolvimento
CMD ["mix", "phx.server"]
