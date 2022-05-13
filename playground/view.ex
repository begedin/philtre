defmodule Playground.View do
  use Phoenix.Component
  use Phoenix.HTML

  import Phoenix.LiveView.Helpers
  import Phoenix.Controller, only: [get_flash: 2]

  alias Philtre.Editor
  alias Playground.Router.Helpers, as: Routes

  def render("root.html", assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <.head {assigns} />
      <body><%= @inner_content %></body>
    </html>
    """
  end

  def render("app.html", assigns) do
    ~H"""
    <main class="container">
      <p class="alert alert-info" role="alert"><%= get_flash(@conn, :info) %></p>
      <p class="alert alert-danger" role="alert"><%= get_flash(@conn, :error) %></p>
      <%= @inner_content %>
    </main>
    """
  end

  def render("live.html", assigns) do
    ~H"""
    <nav class="admin">
      <ul>
        <li><%= live_patch("Home", to: "/") %></li>
        <li><%= live_patch("Index", to: "/documents") %></li>
        <li><%= live_patch("New", to: "/documents/new") %></li>
      </ul>
    </nav>
    <main class="container">
      <p
        class="alert alert-info"
        role="alert"
        phx-click="lv:clear-flash"
        phx-value-key="info"
      >
        <%= live_flash(@flash, :info) %>
      </p>

      <p
        class="alert alert-danger"
        role="alert"
        phx-click="lv:clear-flash"
        phx-value-key="error"
      >
        <%= live_flash(@flash, :error) %>
      </p>

      <%= @inner_content %>
    </main>
    """
  end

  def render("index.html", assigns) do
    ~H"""
    <%= for filename <- @documents do %>
      <h1><a href={filename}><%= filename %></a></h1>
    <% end %>
    """
  end

  def render("show.html", assigns) do
    ~H"""
    <div>
      <h1><%= @conn.path_params["filename"] %></h1>
      <div><%= raw(Editor.html(@document)) %></div>
    </div>
    """
  end

  def render("404.html", assigns) do
    ~H"""
    Not Found
    """
  end

  def render("500.html", assigns) do
    ~H"""
    Internal Server Error
    """
  end

  defp head(assigns) do
    ~H"""
    <head>
      <meta charset="utf-8" />
      <meta http-equiv="X-UA-Compatible" content="IE=edge" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <%= csrf_meta_tag() %>
      <%= live_title_tag(assigns[:page_title] || "Playground", suffix: " · Homepage") %>
      <link
        phx-track-static
        rel="stylesheet"
        href={Routes.static_path(@conn, "/app.css")}
      />
      <script
        defer
        phx-track-static
        type="text/javascript"
        src={Routes.static_path(@conn, "/app.js")}
      >
      </script>
    </head>
    """
  end
end
