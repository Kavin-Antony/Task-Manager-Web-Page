defmodule ApiObanWeb.TaskLiveTest do
  use ApiObanWeb.ConnCase
  import Phoenix.LiveViewTest

  test "can create a new task", %{conn: conn} do
    # Create user
    user =
      ApiOban.Accounts.User
      |> Ash.Changeset.for_create(:register_with_password, %{
        email: "test@example.com",
        password: "password123",
        password_confirmation: "password123"
      })
      |> Ash.create!()

    # Sign in
    conn =
      conn
      |> init_test_session(%{})
      |> AshAuthentication.Plug.Helpers.store_in_session(user)

    {:ok, index_live, _html} = live(conn, ~p"/tasks")

    # Click new task - this should open the modal
    index_live
    |> element("a", "New Task")
    |> render_click()

    # Assert modal title
    assert has_element?(index_live, "h1", "New Task")

    # Trigger validation (this is where it usually fails if for_create is used incorrectly)
    index_live
    |> form("#task-form", task: %{title: "My New Task"})
    |> render_change()

    # Fill form and submit
    assert index_live
           |> form("#task-form", task: %{
             title: "My New Task",
             description: "Test Description",
             status: :todo,
             due_date: DateTime.utc_now() |> DateTime.to_iso8601()
           })
           |> render_submit()

    # Assert success
    assert has_element?(index_live, "p", "My New Task")
  end
end
