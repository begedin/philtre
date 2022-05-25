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

Include the styles in your applicatoon somewhere in your application, for example, from `app.js`:

```js
import 'philtre/dist/index.css';
```

Or from `app.css`:

```css
@import 'philtre/dist/index.css';
```

Import and include the hooks into your live view application

```js
import { ContentEditable, History, Selection } from 'philtre/src/hooks';

const liveSocket = new LiveSocket('/live', Socket, {
  hooks: { ContentEditable, Selection, History },
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
  IO.inspect(json, label: "the json you can now save somehow")
  {:noreply, socket}
end

def handle_info({:update, %Philtre.Editor{} = editor}, socket) do
  {:noreply, assign(socket, :editor, editor)}
end
```

# Developing using Playground

Playground is a locally setup, minimal phoenix application which loads the editor files using local paths, so they are always kept up to date and are even being watched by esbuild.

THis means it allows for live-reload development of hte library.

To start it, run `mix playground`

Note that editor pages are saved as files under `playground\priv\documents` so you should probably periodically clean them.
