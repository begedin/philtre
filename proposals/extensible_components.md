# Proposal: Extensible Components

## Preface

Right now, each new type of section is a new module component.

This keeps things contained, but not not easily managed, as every section is
required to have a

- render function for the live version
- functional component for the static html version
- serialize function (converts component struct to JSON, ie. plain map)
- normalize function (converts serialized function to component struct)
- html function (outputs html string)
- series of event handlers and hooks for managing it's events

## New structure

We introduce a single live component, called `LiveBlock`. This block component
has a well defined interface for managing of the live component.

- `render`
- `handle_event`
- `update`
- etc

Similarly, we introduce a `StaticBlock`, which has a smaller interface for
rendering static content.

- render

The existing (and later new) block types now define a module to which the
LiveBlock and StaticBlock will delegate to.

The delegation happens according to which blocks are registered in the app
configuration.

### Registration

In app configuration we register a block type using something like

```elixir
config, :philtre, :blocks, [
  Philtre.Block.ContentEditable,
  Philtre.Block.Code,
  Philtre.Block.Table
]
```

For this to work, each of the block modules also to define some additional
functions, to allow the LiveBlock and StaticBlock components respecitivly, to
identify where to delegate to, how to handle conversion between blocks, etc.

## Questions

Will conversion between blocks using wildcards work in this system?

How do we deal with blocks being merged together, split, pasted into, etc.?

## Proposed interface for a block

```elixir
defmodule CustomBlock do
  defstruct [:id, ...]

  @doc "Value of the type key in the json representation, to identify the block"
  def type, do: "custom"

  @doc "Wild cards used to convert other blocks into this one"
  def wildcards, do: ["|> ", "/custom"]

  @doc "Functional component to do the live render of this block"
  def live(assigns) do, ~H"Live renderer"

  @doc "Functional component to do the static render of this block"
  def static(assigns), do: ~H"Static renderer"

  @doc "Event handler for all the events this block supports"
  def handle_event(type, params, socket)

  @doc "Converts the block module into plain map that can be serialized into json"
  def serialize(%__MODULE__{}), do: %{}

  @doc "Converts plain map into module struct, idempotent with serialize"
  def normalize(%{}), do: %__MODULE__{}

  @doc "Converts module to raw html string"
  def html(%__MODULE__{}), do: "Raw html string"

  @doc "Converts module to plain text-only content of the block"
  def text(%__MODULE__{}), do: "Plain text string"

  @doc """
  Could be used when pasting other blocks into block, or splitting the block in
  two for some other reason.

  The block would have to be in charge of encoding the position within the
  component, and interpreting it correctly.
  """
  def split(%__MODULE__{}, position_in_this_component), do: :how?

  @doc """
  Another one that's kind of unclear. Used to merge another block into this
  block.

  The block would need to know about specifics of the other block in order for
  this to work.

  We could also move the responsibility into the module of the other block, but
  the same problem is there. Specifics need to be known, or there needs to be
  some common interface.

  Possibly, the other block could be passed in as text or html representation.
  """
  def merge(%__MODULE__{}, other)
end
```
