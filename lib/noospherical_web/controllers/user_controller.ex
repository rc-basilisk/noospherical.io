defmodule NoosphericalWeb.UserController do
  use NoosphericalWeb, :controller

  alias Noospherical.Accounts
  alias Noospherical.Accounts.User

  plug :authenticate_user when action in [:show, :edit, :update]

  plug :authenticate_admin when action in [:index, :delete]

  def action(conn, _) do
    args = [conn, conn.params, conn.assigns.current_user]
    apply(__MODULE__, action_name(conn), args)
  end

  def index(conn, _params, _current_user) do
    users = Accounts.list_users()
    render(conn, "index.html", users: users)
  end

  def new(conn, _params, _current_user) do
    changeset = Accounts.change_registration(%User{}, %{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}, _current_user) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        NoosphericalWeb.Email.welcome_email(user)
        |> NoosphericalWeb.Mailer.deliver_now()

        conn
        |> NoosphericalWeb.Auth.login(user)
        |> put_flash(:info, "#{user.username} created.")
        |> redirect(to: Routes.user_path(conn, :show, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => uuid}, current_user) do
    user =
      Accounts.get_user(uuid)
      |> Noospherical.Repo.preload(:comments)

    render(conn, "show.html", user: user, current_user: current_user)
  end

  def edit(conn, %{"id" => uuid}, current_user) do
    user = Accounts.get_user!(uuid)

    if current_user.uuid == uuid do
      changeset = Accounts.change_user(user)
      render(conn, "edit.html", user: user, changeset: changeset, current_user: current_user)
    else
      conn
      |> put_flash(:error, "hissssss")
      |> redirect(to: Routes.user_path(conn, :show, user))
    end
  end

  def settings(conn, %{"user_id" => uuid}, current_user) do
    user = Accounts.get_user!(uuid)

    if current_user.uuid == uuid do
      changeset = Accounts.change_user(user)
      render(conn, "settings.html", user: user, changeset: changeset, current_user: current_user)
    else
      conn
      |> put_flash(:error, "hissssss")
      |> redirect(to: Routes.user_path(conn, :show, user))
    end
  end

  def update(conn, %{"id" => uuid, "user" => user_params}, current_user) do
    user = Accounts.get_user!(uuid)

    if current_user.uuid == uuid do
      case Accounts.update_user(user, user_params) do
        {:ok, user} ->
          conn
          |> put_flash(:info, "User updated successfully.")
          |> redirect(to: Routes.user_path(conn, :show, user))

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, "edit.html", user: user, changeset: changeset)
      end
    else
      conn
      |> put_flash(:error, "hissssss")
      |> redirect(to: Routes.user_path(conn, :show, user))
    end
  end

  def delete(conn, %{"id" => id}, _current_user) do
    user = Accounts.get_user!(id)
    {:ok, _user} = Accounts.delete_user(user)

    conn
    |> put_flash(:info, "User deleted successfully.")
    |> redirect(to: Routes.user_path(conn, :index))
  end
end
