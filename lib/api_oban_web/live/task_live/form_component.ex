defmodule ApiObanWeb.TaskLive.FormComponent do
  use ApiObanWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage task records.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="task-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input field={@form[:status]} type="select" label="Status" options={[:todo, :in_progress, :done, :overdue, :archived]} />
        <.input field={@form[:due_date]} type="datetime-local" label="Due Date" />

        <:actions>
          <.button phx-disable-with="Saving...">Save Task</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{task: task} = assigns, socket) do
    form =
      if task && task.id do
        AshPhoenix.Form.for_update(
          task,
          :update,
          actor: assigns.current_user,
          as: "task"
        )
      else
        AshPhoenix.Form.for_create(
          ApiOban.Tasks.Task,
          :create,
          actor: assigns.current_user,
          as: "task"
        )
      end
      |> to_form()

    {:ok,
    socket
    |> assign(assigns)
    |> assign(:form, form)}
  end


  @impl true
  def handle_event("validate", %{"task" => task_params}, socket) do
    form =
      socket.assigns.form
      |> AshPhoenix.Form.validate(task_params)

    {:noreply, assign(socket, :form, form)}
  end


  @impl true
  def handle_event("save", %{"task" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: params) do
      {:ok, _task} ->
        {:noreply,
        socket
        |> put_flash(:info, "Task created successfully")
        |> push_patch(to: socket.assigns.patch)}

      {:error, form} ->
        {:noreply, assign(socket, :form, form)}
    end
  end


  # defp save_task(socket, :edit, task_params) do
  #   case ApiOban.Tasks.Task.update_task(socket.assigns.task, task_params, actor: socket.assigns.current_user) do
  #     {:ok, _task} ->
  #       {:noreply,
  #        socket
  #        |> put_flash(:info, "Task updated successfully")
  #        |> push_patch(to: socket.assigns.patch)}

  #     {:error, form} ->
  #       {:noreply, assign_form(socket, form)}
  #   end
  # end

  # defp save_task(socket, :new, task_params) do
  #   case ApiOban.Tasks.Task.create_task(task_params, actor: socket.assigns.current_user) do
  #     {:ok, _task} ->
  #       {:noreply,
  #        socket
  #        |> put_flash(:info, "Task created successfully")
  #        |> push_patch(to: socket.assigns.patch)}

  #     {:error, form} ->
  #       {:noreply, assign_form(socket, form)}
  #   end
  # end

  # defp assign_form(socket, %Ash.Changeset{} = changeset) do
  #   assign(socket, :form, to_form(changeset))
  # end
end
