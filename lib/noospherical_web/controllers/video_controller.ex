defmodule NoosphericalWeb.VideoController do
  use NoosphericalWeb, :controller

  alias Noospherical.Multimedia
  alias Noospherical.Multimedia.Video
  alias Noospherical.Articles

  plug :authenticate_author when action in [:new, :create, :edit, :update, :delete]
  plug :load_categories when action in [:new, :create, :edit, :update]

  defp load_categories(conn, _) do
    assign(conn, :categories, Articles.list_alphabetical_categories())
  end

  def action(conn, _) do
    args = [conn, conn.params, conn.assigns.current_user]
    apply(__MODULE__, action_name(conn), args)
  end

  def index(conn, params, _current_user) do
    page =
      Noospherical.Multimedia.Video
      |> Noospherical.Repo.paginate(params)

    render(conn, "index.html", videos: page.entries, page: page)
  end

  def new(conn, _params, _current_user) do
    changeset = Multimedia.change_video(%Video{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"video" => video_params}, current_user) do
    case Multimedia.create_video(current_user, video_params) do
      {:ok, video} ->
        conn
        |> redirect(to: Routes.video_path(conn, :show, video))
        |> put_flash(:info, "Video created successfully.")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}, _current_user) do
    video =
      Multimedia.get_video!(id)
      |> Noospherical.Repo.preload(:video_comments)

    comment_changeset =
      Noospherical.Multimedia.VideoComment.changeset(%Noospherical.Multimedia.VideoComment{})

    render(conn, "show.html", video: video, comment_changeset: comment_changeset)
  end

  def edit(conn, %{"id" => id}, current_user) do
    video = Multimedia.get_video!(id)

    case video.user_uuid == current_user.uuid || current_user.admin do
      true ->
        changeset = Multimedia.change_video(video)
        render(conn, "edit.html", video: video, changeset: changeset)

      false ->
        conn
        |> put_flash(:error, "Nothing to see here.")
        |> redirect(to: Routes.page_path(conn, :index))
        |> halt()
    end
  end

  def update(conn, %{"id" => id, "video" => video_params}, _current_user) do
    video = Multimedia.get_video!(id)

    case Multimedia.update_video(video, video_params) do
      {:ok, video} ->
        conn
        |> put_flash(:info, "Video updated successfully.")
        |> redirect(to: Routes.video_path(conn, :show, video))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", video: video, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}, current_user) do
    video = Multimedia.get_video!(id)

    case video.user_uuid == current_user.uuid ||
           current_user.admin do
      true ->
        Multimedia.delete_video(video)

        conn
        |> put_flash(:info, "Video deleted successfully.")
        |> redirect(to: Routes.video_path(conn, :index))

      false ->
        conn
        |> put_flash(:error, "Nothing to see here.")
        |> redirect(to: Routes.page_path(conn, :index))
        |> halt()
    end
  end
end
