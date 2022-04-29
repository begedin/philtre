defmodule Playground.ErrorView do
  use Phoenix.View,
    root: "playground/templates",
    namespace: Playground

  # Import convenience functions from controllers
  import Phoenix.Controller,
    only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

  def template_not_found(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
