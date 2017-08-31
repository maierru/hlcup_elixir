# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :hlcup,
  ecto_repos: [Hlcup.Repo]

# Configures the endpoint
# protocol_options: [max_keepalive: :infinity], backlog: 8096
config :hlcup, HlcupWeb.Endpoint,
  http: [
    ip: {0,0,0,0},
    port: 80,
    acceptors: 2500,
    max_connections: :infinity,
    timeout: 2000,
    protocol_options: [{:max_keepalive, 20000000},{:timeout, 2000}]
  ],
  secret_key_base: "EKE6aKpN5XcQaZBIwTe/bAP239aQWl3I8DtNjiEdPc6WObQansS/iHrRDULYn71n",
  render_errors: [view: HlcupWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Hlcup.PubSub,
           adapter: Phoenix.PubSub.PG2]

config :phoenix, :format_encoders,
  json: Phoenix.Jiffy

# Configures Elixir's Logger
config :logger, level: :error
  # удалить отладочные сообщения определенного уровня во время компиляции
  # compile_time_purge_level: :error

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
