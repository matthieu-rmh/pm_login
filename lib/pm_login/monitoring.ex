defmodule PmLogin.Monitoring do
  @moduledoc """
  The Monitoring context.
  """
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias PmLogin.Repo
  alias PmLogin.Kanban
  alias PmLogin.Monitoring.Status
  #Date validations and positive estimation
  def validate_positive_estimated(changeset) do
    est = get_field(changeset, :estimated_duration)
    case est do
      nil -> changeset
      _ -> cond do
      est < 0 -> changeset |> add_error(:negative_estimated, "La durée estimée ne peut être négative")
      true -> changeset
    end
  end
end

def validate_start_deadline(changeset) do
  date_start = get_field(changeset, :date_start)
  deadline = get_field(changeset, :deadline)

  if date_start != nil and deadline != nil do

    dt_start = date_start |> to_string |> string_to_date
    dt_deadline = deadline |> to_string |> string_to_date

    case Date.compare(dt_deadline, dt_start) do
      :lt ->
        changeset |> add_error(:deadline_before_dtstart, "La date d'échéance ne peut pas être antérieure à la date de début")
        _ -> changeset
      end

    else
      changeset
    end
  end

  def validate_start_end(changeset) do
    date_start = get_field(changeset, :date_start)
    date_end = get_field(changeset, :date_end)

    if date_start != nil and date_end != nil do

      dt_start = date_start |> to_string |> string_to_date
      dt_end = date_end |> to_string |> string_to_date

      case Date.compare(dt_end, dt_start) do
        :lt ->
          # IO.puts "startEnd"
          changeset |> add_error(:dt_end_lt_start, "La date finale ne peut pas être antérieure à la date de début")
          _ -> changeset
        end

      else
        changeset
      end
    end

    def validate_dates(changeset) do
      today = Date.utc_today
      date_start = get_field(changeset, :date_start)
      date_end = get_field(changeset, :date_end)
      deadline = get_field(changeset, :deadline)

      # IO.puts(date_start != "" and date_end != "" and deadline != "")
      if date_start != nil and date_end != nil and deadline != nil do

        dt_start = date_start |> to_string |> string_to_date
        dt_end = date_end |> to_string |> string_to_date
        dt_deadline = deadline |> to_string |> string_to_date

        cond do
          Date.compare(dt_start,today) == :lt ->
            changeset
            |> add_error(:date_start_lt, "La date de début ne peut pas être antérieure à aujourd'hui")
            Date.compare(dt_end,today) == :lt ->
              changeset
              |> add_error(:date_end_lt, "La date de fin ne peut pas être antérieure à aujourd'hui")
              Date.compare(dt_deadline,today) == :lt ->
                changeset
                |> add_error(:deadline_lt, "La date d'échéance ne peut pas être antérieure à aujourd'hui")
                true -> changeset
              end
            else
              changeset
            end

          end

          def string_to_date(str) do
            [str_y, str_m, str_d] = String.split(str,"-")
            [y, m, d] = [String.to_integer(str_y), String.to_integer(str_m), String.to_integer(str_d)]
            {:ok, date} = Date.new(y,m,d)
            date
          end

  @doc """
  Returns the list of statuses.

  ## Examples

      iex> list_statuses()
      [%Status{}, ...]

  """
  def list_statuses do
    Repo.all(Status)
  end

  @doc """
  Gets a single status.

  Raises `Ecto.NoResultsError` if the Status does not exist.

  ## Examples

      iex> get_status!(123)
      %Status{}

      iex> get_status!(456)
      ** (Ecto.NoResultsError)

  """
  def get_status!(id), do: Repo.get!(Status, id)

  @doc """
  Creates a status.

  ## Examples

      iex> create_status(%{field: value})
      {:ok, %Status{}}

      iex> create_status(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_status(attrs \\ %{}) do
    %Status{}
    |> Status.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a status.

  ## Examples

      iex> update_status(status, %{field: new_value})
      {:ok, %Status{}}

      iex> update_status(status, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_status(%Status{} = status, attrs) do
    status
    |> Status.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a status.

  ## Examples

      iex> delete_status(status)
      {:ok, %Status{}}

      iex> delete_status(status)
      {:error, %Ecto.Changeset{}}

  """
  def delete_status(%Status{} = status) do
    Repo.delete(status)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking status changes.

  ## Examples

      iex> change_status(status)
      %Ecto.Changeset{data: %Status{}}

  """
  def change_status(%Status{} = status, attrs \\ %{}) do
    Status.changeset(status, attrs)
  end

  alias PmLogin.Monitoring.Project

  @doc """
  Returns the list of projects.

  ## Examples

      iex> list_projects()
      [%Project{}, ...]

  """
  def list_projects do
    Repo.all(Project)
  end

  @doc """
  Gets a single project.

  Raises `Ecto.NoResultsError` if the Project does not exist.

  ## Examples

      iex> get_project!(123)
      %Project{}

      iex> get_project!(456)
      ** (Ecto.NoResultsError)

  """
  def get_project!(id), do: Repo.get!(Project, id)

  @doc """
  Creates a project.

  ## Examples

      iex> create_project(%{field: value})
      {:ok, %Project{}}

      iex> create_project(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_project(attrs \\ %{}) do
    %Project{}
    |> Project.create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a project.

  ## Examples

      iex> update_project(project, %{field: new_value})
      {:ok, %Project{}}

      iex> update_project(project, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_project(%Project{} = project, attrs) do
    project
    |> Project.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a project.

  ## Examples

      iex> delete_project(project)
      {:ok, %Project{}}

      iex> delete_project(project)
      {:error, %Ecto.Changeset{}}

  """
  def delete_project(%Project{} = project) do
    Repo.delete(project)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking project changes.

  ## Examples

      iex> change_project(project)
      %Ecto.Changeset{data: %Project{}}

  """
  def change_project(%Project{} = project, attrs \\ %{}) do
    Project.changeset(project, attrs)
  end

  alias PmLogin.Monitoring.Priority

  @doc """
  Returns the list of priorities.

  ## Examples

      iex> list_priorities()
      [%Priority{}, ...]

  """
  def list_priorities do
    Repo.all(Priority)
  end

  @doc """
  Gets a single priority.

  Raises `Ecto.NoResultsError` if the Priority does not exist.

  ## Examples

      iex> get_priority!(123)
      %Priority{}

      iex> get_priority!(456)
      ** (Ecto.NoResultsError)

  """
  def get_priority!(id), do: Repo.get!(Priority, id)

  @doc """
  Creates a priority.

  ## Examples

      iex> create_priority(%{field: value})
      {:ok, %Priority{}}

      iex> create_priority(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_priority(attrs \\ %{}) do
    %Priority{}
    |> Priority.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a priority.

  ## Examples

      iex> update_priority(priority, %{field: new_value})
      {:ok, %Priority{}}

      iex> update_priority(priority, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_priority(%Priority{} = priority, attrs) do
    priority
    |> Priority.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a priority.

  ## Examples

      iex> delete_priority(priority)
      {:ok, %Priority{}}

      iex> delete_priority(priority)
      {:error, %Ecto.Changeset{}}

  """
  def delete_priority(%Priority{} = priority) do
    Repo.delete(priority)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking priority changes.

  ## Examples

      iex> change_priority(priority)
      %Ecto.Changeset{data: %Priority{}}

  """
  def change_priority(%Priority{} = priority, attrs \\ %{}) do
    Priority.changeset(priority, attrs)
  end

  alias PmLogin.Monitoring.Task

  @doc """
  Returns the list of tasks.

  ## Examples

      iex> list_tasks()
      [%Task{}, ...]

  """
  def list_tasks do
    Repo.all(Task)
  end

  @doc """
  Gets a single task.

  Raises `Ecto.NoResultsError` if the Task does not exist.

  ## Examples

      iex> get_task!(123)
      %Task{}

      iex> get_task!(456)
      ** (Ecto.NoResultsError)

  """
  def get_task!(id), do: Repo.get!(Task, id)

  @doc """
  Creates a task.

  ## Examples

      iex> create_task(%{field: value})
      {:ok, %Task{}}

      iex> create_task(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_task(attrs \\ %{}) do
    %Task{}
    |> Task.changeset(attrs)
    |> Repo.insert()
  end

  def create_task_with_card(attrs \\ %{}) do
    %Task{}
    |> Task.create_changeset(attrs)
    |> Repo.insert()
  end


  @doc """
  Updates a task.

  ## Examples

      iex> update_task(task, %{field: new_value})
      {:ok, %Task{}}

      iex> update_task(task, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_task(%Task{} = task, attrs) do
    task
    |> Task.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a task.

  ## Examples

      iex> delete_task(task)
      {:ok, %Task{}}

      iex> delete_task(task)
      {:error, %Ecto.Changeset{}}

  """
  def delete_task(%Task{} = task) do
    Repo.delete(task)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking task changes.

  ## Examples

      iex> change_task(task)
      %Ecto.Changeset{data: %Task{}}

  """
  def change_task(%Task{} = task, attrs \\ %{}) do
    Task.changeset(task, attrs)
  end

  alias PmLogin.Monitoring.Comment

  @doc """
  Returns the list of comments.

  ## Examples

      iex> list_comments()
      [%Comment{}, ...]

  """
  def list_comments do
    Repo.all(Comment)
  end

  @doc """
  Gets a single comment.

  Raises `Ecto.NoResultsError` if the Comment does not exist.

  ## Examples

      iex> get_comment!(123)
      %Comment{}

      iex> get_comment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_comment!(id), do: Repo.get!(Comment, id)

  @doc """
  Creates a comment.

  ## Examples

      iex> create_comment(%{field: value})
      {:ok, %Comment{}}

      iex> create_comment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_comment(attrs \\ %{}) do
    %Comment{}
    |> Comment.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a comment.

  ## Examples

      iex> update_comment(comment, %{field: new_value})
      {:ok, %Comment{}}

      iex> update_comment(comment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_comment(%Comment{} = comment, attrs) do
    comment
    |> Comment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a comment.

  ## Examples

      iex> delete_comment(comment)
      {:ok, %Comment{}}

      iex> delete_comment(comment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_comment(%Comment{} = comment) do
    Repo.delete(comment)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking comment changes.

  ## Examples

      iex> change_comment(comment)
      %Ecto.Changeset{data: %Comment{}}

  """
  def change_comment(%Comment{} = comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
  end

end