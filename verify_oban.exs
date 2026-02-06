# verify_oban.exs
Application.ensure_all_started(:api_oban)
alias ApiOban.Tasks.Task
alias ApiOban.Accounts.User

IO.puts("Setting up verification...")

# 1. Create a user
email = "oban_test_#{System.unique_integer()}@example.com"
password = "password123"
user = 
  ApiOban.Accounts.User
  |> Ash.Changeset.for_create(:register_with_password, %{email: email, password: password, password_confirmation: password})
  |> Ash.create!(authorize?: false)
IO.puts("User created: #{user.email}")

# 2. Test Archive Trigger (fast)
IO.puts("\n--- Testing Archive Trigger ---")
task = Task.create_task!(%{title: "To Archive", status: :todo, description: "Test"}, actor: user)
IO.puts("Task created with status: #{task.status}")

updated_task = Task.update_task!(task, %{status: :done}, actor: user)
IO.puts("Task updated to: #{updated_task.status}")

IO.puts("Waiting for background job to archive task...")
# Polling for status change
Stream.resource(
  fn -> 0 end,
  fn
    10 -> {:halt, :timeout}
    count ->
      Process.sleep(1000)
      reloaded = Task.get_task!(task.id, actor: user)
      if reloaded.status == :archived do
        {:halt, :success}
      else
        {[reloaded.status], count + 1}
      end
  end,
  fn _ -> :ok end
)
|> Enum.to_list()
|> case do
  :success -> IO.puts("SUCCESS: Task status became :archived")
  :timeout -> IO.puts("FAILURE: Task status did not change to :archived in time")
  e -> IO.puts("Result: #{inspect(e)}")
end


# 3. Test Overdue Scheduler (slow, runs every minute)
IO.puts("\n--- Testing Overdue Scheduler ---")
past_date = DateTime.utc_now() |> DateTime.add(-3600, :second) # 1 hour ago
task_overdue = Task.create_task!(%{title: "Overdue Task", status: :todo, due_date: past_date, description: "Should be marked overdue"}, actor: user)
IO.puts("Task created with due_date: #{task_overdue.due_date} (Status: #{task_overdue.status})")

# Manual check of the filter
require Ash.Query
IO.puts("Manually checking filter...")
results = 
  Task
  |> Ash.Query.filter(status == :todo and due_date < now())
  |> Ash.read!(actor: user)
IO.inspect(results, label: "Manual Query Result")

IO.puts("Waiting for cron job (up to 2 minutes)...")
# Polling
Enum.reduce_while(1..30, :timeout, fn i, _ ->
  Process.sleep(4000)
  reloaded = Task.get_task!(task_overdue.id, actor: user)
  if reloaded.status == :overdue do
    {:halt, :success}
  else
    IO.write(".")
    {:cont, :timeout}
  end
end)
|> case do
  :success -> IO.puts("\nSUCCESS: Task status became :overdue")
  :timeout -> 
    IO.puts("\nFAILURE: Task status did not change to :overdue in time")
    IO.inspect(AshOban.Info.oban_triggers(Task), label: "Triggers")
    IO.inspect(Oban.Job.all() |> Enum.map(&Map.take(&1, [:state, :queue, :worker, :args, :scheduled_at, :errors])), label: "Oban Jobs")
  e -> IO.puts("\nResult: #{inspect(e)}")
end
