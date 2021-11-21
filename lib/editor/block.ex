defmodule Editor.Block do
  defstruct [:id, :type, :content]

  @type t :: %__MODULE__{}

  @spec update_content(t, String.t()) :: t
  def update_content(block, value) do
    block
    |> Map.put(:content, value)
    |> resolve_transform("h1")
    |> resolve_transform("h2")
    |> resolve_transform("h3")
    |> resolve_transform("pre")
  end

  @spec resolve_transform(t, String.t()) :: t
  defp resolve_transform(%{type: type, content: "## " <> _} = block, type) do
    block
  end

  defp resolve_transform(%{content: "# " <> rest} = block, "h1") do
    %{block | type: "h1", content: rest}
  end

  defp resolve_transform(%{content: "#&nbsp;" <> rest} = block, "h1") do
    %{block | type: "h1", content: rest}
  end

  defp resolve_transform(%{content: "## " <> rest} = block, "h2") do
    %{block | type: "h2", content: rest}
  end

  defp resolve_transform(%{content: "##&nbsp;" <> rest} = block, "h2") do
    %{block | type: "h2", content: rest}
  end

  defp resolve_transform(%{content: "### " <> rest} = block, "h3") do
    %{block | type: "h3", content: rest}
  end

  defp resolve_transform(%{content: "###&nbsp;" <> rest} = block, "h3") do
    %{block | type: "h3", content: rest}
  end

  defp resolve_transform(%{content: "```" <> rest} = block, "pre") do
    %{block | type: "pre", content: rest}
  end

  defp resolve_transform(%{} = block, _type), do: block

  @spec downgrade_block(t) :: t
  def downgrade_block(%{type: "h1"} = block), do: %{block | type: "h2"}
  def downgrade_block(%{type: "h2"} = block), do: %{block | type: "h3"}
  def downgrade_block(%{type: "h3"} = block), do: %{block | type: "p"}
  def downgrade_block(%{type: "pre"} = block), do: %{block | type: "p"}
  def downgrade_block(%{} = block), do: block
end
