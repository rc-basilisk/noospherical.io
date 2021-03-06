defmodule NoosphericalWeb.Auth do
  import Plug.Conn
  import Phoenix.Controller
  alias NoosphericalWeb.Router.Helpers, as: Routes

  def init(opts), do: opts

  def call(conn, _opts) do
    user_uuid = get_session(conn, :user_uuid)

    cond do
      conn.assigns[:current_user] ->
        conn

      user = user_uuid && Noospherical.Accounts.get_user(user_uuid) ->
        assign(conn, :current_user, user)

      true ->
        assign(conn, :current_user, nil)
    end
  end

  def login(conn, user) do
    conn
    |> assign(:current_user, user)
    |> assign(:admin, user.admin)
    |> put_session(:user_uuid, user.uuid)
    |> configure_session(renew: true)
  end

  def logout(conn) do
    configure_session(conn, drop: true)
  end

  def authenticate_admin(conn, _opts) do
    if conn.assigns.current_user && conn.assigns.current_user.admin do
      conn
    else
      conn
      |> put_flash(:error, "Nothing to see here.")
      |> redirect(to: Routes.page_path(conn, :index))
      |> halt()
    end
  end

  def authenticate_author(conn, _) do
    if conn.assigns.current_user && conn.assigns.current_user.author do
      conn
    else
      conn
      |> put_flash(:error, "Nothing to see here.")
      |> redirect(to: Routes.page_path(conn, :index))
      |> halt()
    end
  end

  def authenticate_user(conn, _opts) do
    if conn.assigns.current_user do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in to access that page")
      |> redirect(to: Routes.page_path(conn, :index))
      |> halt()
    end
  end
end
