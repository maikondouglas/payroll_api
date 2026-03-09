# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :payroll_api,
  ecto_repos: [PayrollApi.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configure the endpoint
config :payroll_api, PayrollApiWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: PayrollApiWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: PayrollApi.PubSub,
  live_view: [signing_salt: "MJi21GhY"]

# Configure the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :payroll_api, PayrollApi.Mailer, adapter: Swoosh.Adapters.Local

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure Guardian
config :payroll_api, PayrollApi.Auth.Guardian,
  issuer: "payroll_api",
  secret_key: nil

# Configure OpenApiSpex
config :payroll_api, :openapi_spec,
  info: %{
    title: "Payroll API",
    version: "1.0.0"
  }

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
