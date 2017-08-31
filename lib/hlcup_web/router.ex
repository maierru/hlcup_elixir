defmodule HlcupWeb.Router do
  use HlcupWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HlcupWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  scope "/", HlcupWeb do
    pipe_through :api


    get "/users/:id/visits", HighloadController, :user_visits
    get "/locations/:id/avg", HighloadController, :loc_avg
    get "/:type/:id", HighloadController, :item

    post "/:type/new", HighloadController, :new_record
    post "/:type/:item_id", HighloadController, :update_record
  end
end
