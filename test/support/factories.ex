defmodule Philtre.Factories do
  @moduledoc """
  Contains test factories
  """
  alias Philtre.Articles

  @article_params %Editor{
    blocks: [
      %Editor.Block{
        id: Editor.Utils.new_id(),
        type: "h1",
        cells: [%Editor.Cell{id: Editor.Utils.new_id(), type: "span", content: "My Article"}]
      },
      %Editor.Block{
        id: Editor.Utils.new_id(),
        type: "p",
        cells: [%Editor.Cell{id: Editor.Utils.new_id(), type: "span", content: "My Content"}]
      }
    ]
  }

  @spec create_article(Editor.t()) :: Articles.Article.t()
  def create_article(%Editor{} = editor \\ @article_params) do
    {:ok, article} = Articles.create_article(editor)
    article
  end

  @spec create_articles(list(Editor.t())) :: list(Articles.Article.t())
  def create_articles(params) when is_list(params) do
    Enum.map(params, &create_article/1)
  end

  @spec create_articles(pos_integer, map) :: list(Articles.Article.t())
  def create_articles(count, %Editor{} = editor \\ @article_params)
      when is_integer(count) and count > 1 do
    Enum.map(1..count, fn index ->
      editor = Map.merge(@article_params, editor)

      editor = %{
        editor
        | blocks:
            Enum.map(editor.blocks, fn %Editor.Block{} = block ->
              %Editor.Block{
                type: block.type,
                id: Editor.Utils.new_id(),
                cells: Enum.map(block.cells, &%{&1 | content: "#{&1.content} #{index}"})
              }
            end)
      }

      create_article(editor)
    end)
  end
end
