# Description

A block-style content editor, with support for static html generation, in phoenix live view.

# Installation

Add it to your dependencies in `mix.exs`:

```Elixir
deps: [
  # ...
  {:philtre, "~> 0.9"}
]
```

Install it as an npm dependency using `npm -i -s philtrejs`.

```json
"dependencies": {
  "philtre": "philtrejs"
},
```

Alternatively, just include it in your /assets/package.json directly from the hex
installation:

```json
"dependencies": {
  "philtre": "file:../deps/philtre"
},
```

Include `philtre.scss` somewhere in your application, for example, from `app.js`:

```js
import 'philtre/src/css/philtre.scss';
```

Import and include the hooks into your live view application

```js
import { ContentEditable, History, Selection } from 'philtre/src/hooks';

// ...

const liveSocket = new LiveSocket('/live', Socket, {
  hooks: { ContentEditable, Selection, History },
  // ...
});
```

Render the page component inside one of your live views

```Elixir
def mount(%{}, _session, socket) do
  {:ok, assign(socket, %{editor: Philtre.Editor.new()})}
end

def render(assigns) do
  ~H"""
  <button phx-click="save">Save</button>
  <.live_component
    module={Philtre.UI.Page}
    id={@editor.id}
    editor={@editor}
  />
  """
end

def handle_event("save", %{}, socket) do
  json = Philtre.Editor.serialize(socket.assigns.json)
  # save the json however you please
  {:noreply, socket}
end

def handle_info({:update, %Editor{} = editor}, socket) do
  {:noreply, assign(socket, :editor, editor)}
end
```

# Playground

To start your Phoenix server:

- Install dependencies with `mix deps.get`
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

- Official website: https://www.phoenixframework.org/
- Guides: https://hexdocs.pm/phoenix/overview.html
- Docs: https://hexdocs.pm/phoenix
- Forum: https://elixirforum.com/c/phoenix-forum
- Source: https://github.com/phoenixframework/phoenix
