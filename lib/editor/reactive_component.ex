defmodule Editor.ReactiveComponent do
  defmacro __using__(opts) do
    quote do
      require Logger

      def update(%{event: event, payload: payload}, socket) do
        opts = unquote(opts)
        events = Keyword.get(opts, :events, [])

        if event in events do
          on(socket, event, payload)
        else
          Logger.info("#{__MODULE__}:#{socket.assigns.myself} received invalid event '#{event}'")
        end

        {:ok, socket}
      end

      defp emit(%Phoenix.LiveView.Socket{} = socket, event, payload) when is_binary(event) do
        send(self(), {:emit, event, socket.assigns.parent, payload})
      end

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_) do
    quote do
      defp on(socket, _event, _payload) do
        {:ok, socket}
      end

      defoverridable on: 3, update: 2
    end
  end
end
