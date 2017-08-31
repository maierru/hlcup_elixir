# Hlcup

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](http://www.phoenixframework.org/docs/deployment).

## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: http://phoenixframework.org/docs/overview
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix

$ MIX_ENV=prod mix deps.get
$ MIX_ENV=prod mix deps.compile
$ MIX_ENV=prod mix release --env=prod --verbose

$ sudo MIX_ENV=prod iex --erl "+K true +stbt db" -S mix phx.server
$ MIX_ENV=prod mix release --erl="+K true +stbt db -env ERL_MAX_PORTS 4096" --env=prod --verbose

> :inet.i
> Application.get_env(:hlcup, HlcupWeb.Endpoint)
> :ets.lookup(:"Elixir.HlcupWeb.Endpoint", :http)
> :erlang.system_info(:process_limit)
> :erlang.system_info(:port_limit)
> :erlang.system_info(:schedulers)
> :erlang.system_info(:schedulers_online)
> :erlang.statistics(:run_queue)

$
