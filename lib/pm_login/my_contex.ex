defmodule PmLogin.MyContex do
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias PmLogin.Repo
  alias PmLogin.Monitoring

  def todays_dataset do
    todays = Monitoring.list_achieved_tasks_today
    # IO.inspect todays
    IO.puts length(todays)
    case length(todays) do
      0 -> "Aucune tâche accomplie ce jour"
      _ ->


        data = Enum.map(todays, fn(task) -> %{category_col: task.priority_id,
              task_col: task.title, start_col: date_to_datetime(task.date_start), finish_col: naive_to_datetime(task.achieved_at)} end)
        dataset = Contex.Dataset.new(data)

        list = Enum.map(todays, fn(task) -> [task.priority_id, task.title, date_to_datetime(task.date_start), naive_to_datetime(task.achieved_at)] end)
        # list = [[]]
        list_dataset = Contex.Dataset.new(list)
        # IO.inspect list_dataset
        # plot_content = Contex.GanttChart.new(dataset, mapping: %{category_col: :category_col, task_col: :task_col, start_col: :start_col, finish_col: :finish_col} )
        plot_content = Contex.GanttChart.new(list_dataset)


        plot = Contex.Plot.new(900, 600, plot_content)
          |> Contex.Plot.titles("Diagramme de Gantt pour les tâches effectuées aujourd'hui", nil)
        output = Contex.Plot.to_svg(plot)
    end

  end

  def this_week_dataset do
    this_weeks = Monitoring.list_achieved_tasks_this_week

    case length(this_weeks) do
      0 -> "Aucune tâche accomplie cette semaine"
      _ ->
        data = Enum.map(this_weeks, fn(task) -> %{category_col: task.priority_id,
        task_col: task.title, start_col: date_to_datetime(task.date_start), finish_col: naive_to_datetime(task.achieved_at)} end)
        dataset = Contex.Dataset.new(data)

        list = Enum.map(this_weeks, fn(task) -> [task.priority_id, task.title, date_to_datetime(task.date_start), naive_to_datetime(task.achieved_at)] end)

        list_dataset = Contex.Dataset.new(list)
        # IO.inspect list_dataset
        # plot_content = Contex.GanttChart.new(dataset, mapping: %{category_col: :category_col, task_col: :task_col, start_col: :start_col, finish_col: :finish_col} )
        plot_content = Contex.GanttChart.new(list_dataset)


        plot = Contex.Plot.new(900, 600, plot_content)
          |> Contex.Plot.titles("Diagramme de Gantt pour les tâches effectuées cette semaine", nil)
        output = Contex.Plot.to_svg(plot)
    end

  end

  @spec this_month_dataset :: {:safe, [...]}
  def this_month_dataset do
    this_months = Monitoring.list_achieved_tasks_this_month

    case length(this_months) do
      0 -> "Aucune tâche accomplie ce mois"
      _ ->
        data = Enum.sort_by(this_months, fn(task) -> task.priority_id end)
        |> Enum.map(fn(task) ->
        [task.priority_id, task.title, date_to_naive(task.date_start), task.achieved_at]
      end)


      # IO.inspect data
        dataset = Contex.Dataset.new(data, ["Cat", "Task", "Start", "End"])
        plot_content = Contex.GanttChart.new(dataset)

        plot = Contex.Plot.new(900, 600, plot_content)
          |> Contex.Plot.titles("Diagramme de Gantt pour les tâches effectuées ce mois-ci", nil)

          Contex.Plot.to_svg(plot)
        # OLD DATASET
        # data = Enum.map(this_months, fn(task) -> %{category_col: task.priority_id,
        # task_col: task.title, start_col: date_to_datetime(task.date_start), finish_col: naive_to_datetime(task.achieved_at)} end)
        # dataset = Contex.Dataset.new(data)

        # list = Enum.map(this_months, fn(task) -> [task.priority_id, task.title, date_to_datetime(task.date_start), naive_to_datetime(task.achieved_at)] end)

        # list_dataset = Contex.Dataset.new(list)
        # IO.inspect list_dataset
        # # plot_content = Contex.GanttChart.new(dataset, mapping: %{category_col: :category_col, task_col: :task_col, start_col: :start_col, finish_col: :finish_col} )
        # plot_content = Contex.GanttChart.new(list_dataset)


        # plot = Contex.Plot.new(1200, 800, plot_content)
        # output = Contex.Plot.to_svg(plot)
    end

  end

  def test_dataset do
    this_months = Monitoring.list_achieved_tasks_this_month

    case length(this_months) do
      0 -> "Aucune tâche accomplie "
      _ ->
        data = Enum.sort_by(this_months, fn(task) -> task.priority_id end)
          |> Enum.map(fn(task) ->
          [task.priority_id, task.title, date_to_naive(task.date_start), task.achieved_at]
        end)


        # IO.inspect data
        # dataset = Contex.Dataset.new(data, ["Cat", "Task", "Start", "End"])
        # plot_content = Contex.GanttChart.new(dataset)

        # plot = Contex.Plot.new(600, 400, plot_content)
        #   |> Contex.Plot.titles("Sample Gantt Chart", nil)

        #   Contex.Plot.to_svg(plot)

        # list = Enum.map(this_months, fn(task) -> [task.priority_id, task.title, date_to_datetime(task.date_start), naive_to_datetime(task.achieved_at)] end)

        # list_dataset = Contex.Dataset.new(list)
        # IO.inspect list_dataset
        # # plot_content = Contex.GanttChart.new(dataset, mapping: %{category_col: :category_col, task_col: :task_col, start_col: :start_col, finish_col: :finish_col} )
        # plot_content = Contex.GanttChart.new(list_dataset)


        # plot = Contex.Plot.new(1200, 800, plot_content)
        # output = Contex.Plot.to_svg(plot)
    end

  end

  def naive_to_datetime(naive) do
    {:ok, datetime} = DateTime.from_naive(naive, "Etc/UTC")
    datetime
  end

  def date_to_naive(date) do
    {:ok, naive} = {Date.to_erl(date),{0,0,0}} |> NaiveDateTime.from_erl
    naive
  end

  def date_to_datetime(date) do
    {:ok, naive} = {Date.to_erl(date),{0,0,0}} |> NaiveDateTime.from_erl
    naive_to_datetime(naive)
  end

#   plot_content = BarPlot.new(dataset, 100, 100, orientation)
#   |> BarPlot.defaults()
#   |> BarPlot.type(:stacked)
#   |> BarPlot.padding(2)
#   |> BarPlot.set_val_col_names(Enum.map(1..nseries, fn i -> "Value#{i}" end))
#
# plot = Plot.new(600, 350, plot_content)
#   |> Plot.plot_options(%{legend_setting: :legend_right})
#   |> Plot.titles("Title", nil)
#   |> Plot.plot_options(%{show_y_axis: true})
#
# {:safe, Plot.to_svg(plot)}
#
# image
#
# And for the above
#
# dataset = Reaction.Chart.Dataset.new(data, ["Cat", "Task", "Start", "End"])
# plot_content = GanttChart.new(dataset, 100, 100)
#   |> GanttChart.defaults()
#
# plot = Plot.new(600, 400, plot_content)
#   |> Plot.titles("Test Gantt", nil)
#
# {:safe, Plot.to_svg(plot)}



end
