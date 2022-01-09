defmodule PhiltreWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use PhiltreWeb, :controller
      use PhiltreWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  @type session :: %Phoenix.LiveView.Session{}

  def controller do
    quote do
      use Phoenix.Controller, namespace: PhiltreWeb

      import Plug.Conn
      import PhiltreWeb.Gettext
      alias PhiltreWeb.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/philtre_web/templates",
        namespace: PhiltreWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {PhiltreWeb.LayoutView, "live.html"}

      alias Phoenix.LiveView

      unquote(view_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent
      alias Phoenix.LiveView

      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import PhiltreWeb.Gettext
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import LiveView and .heex helpers (live_render, live_patch, <.form>, etc)
      import Phoenix.LiveView.Helpers

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import PhiltreWeb.ErrorHelpers
      import PhiltreWeb.Gettext
      alias PhiltreWeb.Router.Helpers, as: Routes
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
