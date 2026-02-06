defmodule ApiObanWeb.TaskLive.Index do
  use ApiObanWeb, :live_view

  require Ash.Query

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
      <div class="px-4 py-6 sm:px-0">
        <div class="flex justify-between items-center mb-8">
          <h1 class="text-3xl font-bold text-gray-900 dark:text-white">My Tasks</h1>
          <.link patch={~p"/tasks/new"} class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
            <svg class="-ml-1 mr-2 h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z" clip-rule="evenodd" />
            </svg>
            New Task
          </.link>
        </div>

        <div class="bg-white dark:bg-gray-800 shadow overflow-hidden sm:rounded-md">
          <ul role="list" class="divide-y divide-gray-200 dark:divide-gray-700">
            <%= for task <- @tasks do %>
              <li class="relative">
                <div class="px-4 py-4 sm:px-6 hover:bg-gray-50 dark:hover:bg-gray-750 transition duration-150 ease-in-out">
                  <div class="flex items-center justify-between">
                    <div class="flex-1 min-w-0 pr-4">
                      <p class="text-lg font-medium text-indigo-600 truncate"><%= task.title %></p>
                      <div class="flex items-center mt-2">
                        <%= status_badge(task.status) %>
                        <p class="ml-4 text-sm text-gray-500 dark:text-gray-400 truncate"><%= task.description %></p>
                      </div>
                    </div>
                    <div class="flex-shrink-0 flex flex-col items-end space-y-2">
                       <div class="flex text-sm text-gray-500 dark:text-gray-400">
                        <svg class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                          <path fill-rule="evenodd" d="M6 2a1 1 0 00-1 1v1H4a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1V3a1 1 0 10-2 0v1H7V3a1 1 0 00-1-1zm0 5a1 1 0 000 2h8a1 1 0 100-2H6z" clip-rule="evenodd" />
                        </svg>
                        <p>
                          Due on
                          <%= if task.due_date do %>
                            <time datetime={task.due_date}>
                              <%= Calendar.strftime(task.due_date, "%b %d, %Y") %>
                            </time>
                          <% else %>
                            <span>No due date</span>
                          <% end %>
                        </p>

                      </div>
                      <div class="relative z-10 flex space-x-2">
                         <.link patch={~p"/tasks/#{task}/edit"} class="text-sm text-indigo-600 hover:text-indigo-900 font-medium">Edit</.link>
                         <button phx-click="delete" phx-value-id={task.id} data-confirm="Are you sure?" class="text-sm text-red-600 hover:text-red-900 font-medium">Delete</button>
                      </div>
                    </div>
                  </div>
                </div>
              </li>
            <% end %>
          </ul>
        </div>
      </div>
    </div>

    <.modal :if={@live_action in [:new, :edit]} id="task-modal" show on_cancel={JS.patch(~p"/tasks")}>
      <.live_component
        module={ApiObanWeb.TaskLive.FormComponent}
        id={@task.id || :new}
        title={@page_title}
        action={@live_action}
        task={@task}
        current_user={@current_user}
        patch={~p"/tasks"}
      />
    </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
       # Subscribe to task updates if we want real-time updates later
       # ApiOban.Tasks.subscribe!()
    end

    {:ok, stream(socket, :tasks, []) |> assign_tasks()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Task")
    |> assign(:task, ApiOban.Tasks.Task.get_task!(id, actor: socket.assigns.current_user))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Task")
    |> assign(:task, %ApiOban.Tasks.Task{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Tasks")
    |> assign(:task, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    task = ApiOban.Tasks.Task.get_task!(id, actor: socket.assigns.current_user)
    ApiOban.Tasks.Task.destroy_task!(task, actor: socket.assigns.current_user)

    {:noreply, assign_tasks(socket)}
  end

  defp assign_tasks(socket) do
    tasks =
      ApiOban.Tasks.Task
      |> Ash.Query.for_read(:read, %{}, actor: socket.assigns.current_user)
      |> Ash.read!()

    assign(socket, :tasks, tasks)
  end

  defp status_badge(status) do
    color = case status do
      :todo -> "bg-gray-100 text-gray-800"
      :in_progress -> "bg-yellow-100 text-yellow-800"
      :done -> "bg-green-100 text-green-800"
      :overdue -> "bg-red-100 text-red-800"
      :archived -> "bg-slate-100 text-slate-800"
      _ -> "bg-gray-100 text-gray-800"
    end

    humanized = status |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()

    assigns = %{color: color, status: humanized}

    ~H"""
    <span class={["inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium", @color]}>
      <%= @status %>
    </span>
    """
  end
end
