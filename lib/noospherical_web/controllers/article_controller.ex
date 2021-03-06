defmodule NoosphericalWeb.ArticleController do
  use NoosphericalWeb, :controller

  alias Noospherical.Articles
  alias Noospherical.Articles.Article

  plug :authenticate_author when action in [:new, :create, :edit, :update, :delete]
  plug :load_categories when action in [:new, :create, :edit, :update]

  defp load_categories(conn, _article) do
    assign(conn, :categories, Articles.list_alphabetical_categories())
  end

  def action(conn, _) do
    args = [conn, conn.params, conn.assigns.current_user]
    apply(__MODULE__, action_name(conn), args)
  end

  def index(conn, params, _current_user) do
    page =
      Articles.Article
      |> Noospherical.Repo.paginate(params)

    render(conn, "index.html", articles: page.entries, page: page)
  end

  def new(conn, _params, _current_user) do
    changeset = Articles.change_article(%Article{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"article" => article_params}, current_user) do
    case Articles.create_article(current_user, article_params) do
      {:ok, article} ->
        conn
        |> put_flash(:info, "Article created successfully.")
        |> redirect(to: Routes.article_path(conn, :show, article))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}, _current_user) do
    article =
      Articles.get_article!(id)
      |> Noospherical.Repo.preload(:comments)

    comment_changeset = Articles.Comment.changeset(%Articles.Comment{})

    render(conn, "show.html",
      article: article,
      comment_changeset: comment_changeset
    )
  end

  def edit(conn, %{"id" => id}, current_user) do
    article = Articles.get_article!(id)

    case article.user_uuid == current_user.uuid ||
           current_user.admin do
      true ->
        changeset = Articles.change_article(article)
        render(conn, "edit.html", article: article, changeset: changeset)

      false ->
        conn
        |> put_flash(:error, "Nothing to see here.")
        |> redirect(to: Routes.page_path(conn, :index))
        |> halt()
    end
  end

  def update(conn, %{"id" => id, "article" => article_params}, _current_user) do
    article = Articles.get_article!(id)

    case Articles.update_article(article, article_params) do
      {:ok, article} ->
        conn
        |> put_flash(:info, "Article updated successfully.")
        |> redirect(to: Routes.article_path(conn, :show, article))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", article: article, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}, current_user) do
    article = Articles.get_article!(id)

    case article.user_uuid == current_user.uuid ||
           current_user.admin do
      true ->
        Articles.delete_article(article)

      false ->
        conn
        |> put_flash(:error, "Nothing to see here.")
        |> redirect(to: Routes.page_path(conn, :index))
        |> halt()
    end

    conn
    |> put_flash(:info, "Article deleted successfully.")
    |> redirect(to: Routes.article_path(conn, :index))
  end
end
