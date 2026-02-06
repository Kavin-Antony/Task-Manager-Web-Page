defmodule ApiOban.Tasks.Task do
  use Ash.Resource,
    otp_app: :api_oban,
    domain: ApiOban.Tasks,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshGraphql.Resource, AshJsonApi.Resource, AshOban],
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "tasks"
    repo ApiOban.Repo
  end

  code_interface do
    define :create_task, action: :create
    define :update_task, action: :update
    define :get_task, action: :read, get_by: [:id]
    define :mark_overdue, action: :mark_overdue
    define :archive, action: :archive
    define :destroy_task, action: :destroy
  end

  json_api do
    type "task"

    routes do
      base "/tasks"
      get :read
      index :read
      post :create
      patch :update
      delete :destroy
    end
  end

  graphql do
    type :task

    queries do
      get :get_task, :read
      list :list_tasks, :read
    end

    mutations do
      create :create_task, :create
      update :update_task, :update
      destroy :destroy_task, :destroy
    end
  end

  oban do
    triggers do
      trigger :archive do
        action :archive
        where expr(status == :done)
        worker_module_name ApiOban.Tasks.Task.AshOban.Worker.Archive
        scheduler_module_name ApiOban.Tasks.Task.AshOban.Scheduler.Archive
      end

      trigger :mark_overdue do
        action :mark_overdue
        where expr(status == :todo and due_date < now())
        scheduler_cron "*/1 * * * *"
        worker_module_name ApiOban.Tasks.Task.AshOban.Worker.MarkOverdue
        scheduler_module_name ApiOban.Tasks.Task.AshOban.Scheduler.MarkOverdue
      end
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:title, :description, :status, :due_date]
      change relate_actor(:user)
    end

    update :update do
      accept [:title, :description, :status, :due_date]
    end

    update :mark_overdue do
      change set_attribute(:status, :overdue)
    end

    update :archive do
      change set_attribute(:status, :archived)
    end
  end

  policies do
    policy action(:mark_overdue) do
      authorize_if always()
    end

    policy action(:archive) do
      authorize_if always()
    end

    policy action_type(:read) do
      authorize_if expr(user_id == ^actor(:id))
    end

    policy action_type(:create) do
      authorize_if actor_present()
    end

    policy action_type(:update) do
      authorize_if expr(user_id == ^actor(:id))
    end

    policy action_type(:destroy) do
      authorize_if expr(user_id == ^actor(:id))
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :title, :string do
      allow_nil? false
    end

    attribute :description, :string

    attribute :status, :atom do
      constraints one_of: [:todo, :in_progress, :done, :overdue, :archived]
      default :todo
      allow_nil? false
    end

    attribute :due_date, :utc_datetime

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :user, ApiOban.Accounts.User do
      allow_nil? false
    end
  end

  identities do
    identity :unique_task_by_user, [:user_id, :title]
  end
end
