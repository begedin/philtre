defmodule Philtre.Factories do
  @moduledoc """
  Contains test factories
  """
  alias Philtre.Articles

  @article_params %Editor{
    blocks: [
      %Editor.Block.H1{
        active: false,
        id: Editor.Utils.new_id(),
        post_caret: "",
        pre_caret: "Fake page"
      },
      %Editor.Block.P{
        active: true,
        id: Editor.Utils.new_id(),
        post_caret: "",
        pre_caret: "My content"
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

  @spec create_articles(pos_integer) :: list(Articles.Article.t())
  def create_articles(count) when is_integer(count) and count > 1 do
    1..count
    |> Enum.map(fn index ->
      %Editor{
        id: "editor_#{index}",
        blocks: [
          %Editor.Block.H1{
            active: false,
            id: Editor.Utils.new_id(),
            post_caret: "",
            pre_caret: "Fake page #{index}"
          },
          %Editor.Block.P{
            active: true,
            id: Editor.Utils.new_id(),
            post_caret: "",
            pre_caret: "My content"
          }
        ]
      }
    end)
    |> Enum.map(&create_article/1)
  end
end
