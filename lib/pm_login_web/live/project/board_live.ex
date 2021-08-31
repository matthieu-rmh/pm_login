defmodule PmLoginWeb.Project.BoardLive do
  use Phoenix.LiveView

  alias PmLoginWeb.LiveComponent.{TaskModalLive,PlusModalLive,ModifModalLive,CommentsModalLive,SecondaryModalLive}

  alias PmLoginWeb.ProjectView
  alias PmLogin.Monitoring
  alias PmLogin.Kanban
  alias PmLogin.Monitoring.{Task, Priority}
  alias PmLogin.Login
  alias PmLogin.Login.User
  alias PmLogin.Services
  alias PmLogin.Monitoring.Comment
  alias PmLoginWeb.Router.Helpers, as: Routes


  def mount(_params,%{"curr_user_id" => curr_user_id ,"pro_id" => pro_id}, socket) do
    if connected?(socket), do: Kanban.subscribe()
    Monitoring.subscribe()
    Monitoring.hidden_subscribe()
    Services.subscribe()

    layout = case Login.get_user!(curr_user_id).right_id do
      1 -> {PmLoginWeb.LayoutView, "board_layout_live.html"}
      2 -> {PmLoginWeb.LayoutView, "attributor_board_live.html"}
      3 -> {PmLoginWeb.LayoutView, "contributor_board_live.html"}
      _ -> {}
    end


    project = Monitoring.get_project!(pro_id)

    task_changeset = Monitoring.change_task(%Task{})
    modif_changeset = Monitoring.change_task(%Task{})

    priorities = Monitoring.list_priorities
    list_priorities = Enum.map(priorities, fn (%Priority{} = p)  -> {p.title, p.id} end)

    contributors = Login.list_contributors
    list_contributors = Enum.map(contributors, fn (%User{} = p)  -> {p.username, p.id} end)

    secondary_changeset = Monitoring.change_task(%Task{})
    my_primary_tasks = Monitoring.list_primary_tasks(pro_id)
    list_primaries = my_primary_tasks |> Enum.map(fn (%Task{} = p) -> {p.title, p.id} end)

    board = Kanban.get_board!(project.board_id)

    IO.inspect board.stages

    primary_stages = board.stages
    |> Enum.map(fn (%Kanban.Stage{} = stage) ->
      struct(stage, cards: cards_list_primary_tasks(stage.cards))
    end)

    primary_board = struct(board, stages: primary_stages)

    {:ok, socket |> assign(is_attributor: Monitoring.is_attributor?(curr_user_id),is_admin: Monitoring.is_admin?(curr_user_id), show_plus_modal: false,curr_user_id: curr_user_id, pro_id: pro_id, show_secondary: false, showing_primaries: true,
                    contributors: list_contributors, priorities: list_priorities, board: primary_board, show_task_modal: false, show_modif_modal: false, card: nil,
                    primaries: list_primaries, is_contributor: Monitoring.is_contributor?(curr_user_id),task_changeset: task_changeset, modif_changeset: modif_changeset, show_comments_modal: false, card_with_comments: nil,
                    show_modal: false, arch_id: nil,show_notif: false, notifs: Services.list_my_notifications_with_limit(curr_user_id, 4), secondary_changeset: secondary_changeset, comment_changeset: Monitoring.change_comment(%Comment{}),
                    no_selected_hidden: false, show_hidden_modal: false, hidden_tasks: Monitoring.list_hidden_tasks(pro_id), project_contributors: Monitoring.list_project_contributors(board), project_attributors: Monitoring.list_project_attributors(board))
                    |> allow_upload(:file, accept: ~w(.png .jpeg .jpg .pdf .txt .odt .ods .odp .odg .csv .xml .xls .xlsx .xlsm .ppt .pptx .doc .docx), max_entries: 5),
                     layout: layout
                  }
  end

  def cards_list_filtered(old_list, attrib_id) do
    old_list |> Enum.filter(fn card -> card.task.attributor_id == attrib_id end)
  end

  def cards_list_contrib_filtered(old_list, contrib_id) do
    old_list |> Enum.filter(fn card -> card.task.contributor_id == contrib_id end)
  end

  def cards_list_primary_tasks(old_list) do
    old_list |> Enum.filter(fn card -> is_nil(card.task.parent_id) end)
  end

  def cards_list_secondary_tasks(old_list) do
    old_list |> Enum.filter(fn card -> not is_nil(card.task.parent_id) end)
  end

  def cards_list_filtered_nocontributor(old_list) do
    old_list |> Enum.filter(fn card -> is_nil(card.task.contributor_id) end)
  end

  def cards_list_searched(old_list, text) do
    old_list |> Enum.filter(fn card -> Monitoring.filter_task_title(text, card.task.title) end)
  end

  # def handle_event("inspect_tasks", _params, socket) do
  #   board = Kanban.get_board!(socket.assigns.board.id)
  #   IO.inspect(Monitoring.list_project_contributors(board))
  #   IO.inspect(board)
  #   {:noreply, socket}
  # end

  def handle_event("achieve", params, socket) do
    IO.puts "achevement"
    IO.inspect params
    task = Monitoring.get_task_with_card!(params["id"])
    IO.inspect task
    # IO.inspect socket.assigns.board.stages
    {:noreply, socket}
  end

  def handle_event("spin_test", _params, socket) do
    {:noreply, socket |> push_event("SpinTest", %{})}
  end

  def handle_event("go_archive", %{"id" => id}, socket) do
    {:noreply, socket |> assign(show_modal: true, arch_id: id)}
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply, socket |> assign(show_modal: false)}
  end

  def handle_event("archive_task", %{"id" => id}, socket) do
    task = Monitoring.get_task!(id)
    Monitoring.hide_task(task)

    cond do
      Monitoring.is_task_mother?(task) ->
                                          # IO.puts "madafaka"
                                          task_with_children = Monitoring.get_task_mother!(task.id)
                                          # IO.puts length(task_with_children.children)
                                          # IO.inspect(task_with_children.children)
                                          for child <- task_with_children.children do
                                            Monitoring.hide_task(child)
                                          end
      true -> IO.puts "not mdfk"
    end

    curr_user_id = socket.assigns.curr_user_id
    content = "Tâche #{task.title} archivée par #{Login.get_user!(curr_user_id).username}."
    Services.send_notifs_to_admins_and_attributors(curr_user_id, content)
    {:noreply, socket |> assign(show_modal: false) |>put_flash(:info, "Tâche #{task.title} archivée.") |> push_event("AnimateAlert", %{})}
  end

  def handle_event("attributor_selected", %{"_target" => ["attributor_select"], "attributor_select" => id}, socket) do
    attrib_id = String.to_integer(id)

    stages = case attrib_id do
      9000 -> Kanban.get_board!(socket.assigns.board.id).stages
      _ ->
        Kanban.get_board!(socket.assigns.board.id).stages
            |> Enum.map(fn (%Kanban.Stage{} = stage) ->
              struct(stage, cards: cards_list_filtered(stage.cards, attrib_id))
        end)

    end


    current_board = Kanban.get_board!(socket.assigns.board.id)
    board = struct(current_board, stages: stages)

    new_stages = case socket.assigns.showing_primaries do
      true -> stages
          |> Enum.map(fn (%Kanban.Stage{} = stage) ->
            struct(stage, cards: cards_list_primary_tasks(stage.cards))
      end)

      _ ->
        stages
            |> Enum.map(fn (%Kanban.Stage{} = stage) ->
              struct(stage, cards: cards_list_secondary_tasks(stage.cards))
        end)

    end

    # current_board = Kanban.get_board!(socket.assigns.board.id)
    new_board = struct(board, stages: new_stages)

    {:noreply, socket
    |> assign(board: new_board)
  }
  end

  def handle_event("attributor_selected", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("contributor_selected", %{"_target" => ["contributor_select"], "contributor_select" => id}, socket) do
    contrib_id = String.to_integer(id)

    stages = case contrib_id do
      9000 -> Kanban.get_board!(socket.assigns.board.id).stages
      -1 ->
        Kanban.get_board!(socket.assigns.board.id).stages
            |> Enum.map(fn (%Kanban.Stage{} = stage) ->
              struct(stage, cards: cards_list_filtered_nocontributor(stage.cards))
        end)
      _ ->
        Kanban.get_board!(socket.assigns.board.id).stages
            |> Enum.map(fn (%Kanban.Stage{} = stage) ->
              struct(stage, cards: cards_list_contrib_filtered(stage.cards, contrib_id))
        end)

    end

    current_board = Kanban.get_board!(socket.assigns.board.id)
    board = struct(current_board, stages: stages)

    new_stages = case socket.assigns.showing_primaries do
      true -> stages
          |> Enum.map(fn (%Kanban.Stage{} = stage) ->
            struct(stage, cards: cards_list_primary_tasks(stage.cards))
      end)

      _ ->
        stages
            |> Enum.map(fn (%Kanban.Stage{} = stage) ->
              struct(stage, cards: cards_list_secondary_tasks(stage.cards))
        end)

    end

    # current_board = Kanban.get_board!(socket.assigns.board.id)
    new_board = struct(board, stages: new_stages)

    {:noreply, socket
    |> assign(board: new_board)
  }
  end

  def handle_event("contributor_selected", %{"_target" => ["contributor_select"]}, socket) do
    {:noreply, socket}
  end


  def handle_event("distinct_task", %{"_target" => ["task_view"], "task_view" => radio_value}, socket) do
    IO.inspect(radio_value)

    stages = case radio_value do
      "task" ->  Kanban.get_board!(socket.assigns.board.id).stages
          |> Enum.map(fn (%Kanban.Stage{} = stage) ->
            struct(stage, cards: cards_list_primary_tasks(stage.cards))
      end)

      "subtask" ->
        Kanban.get_board!(socket.assigns.board.id).stages
            |> Enum.map(fn (%Kanban.Stage{} = stage) ->
              struct(stage, cards: cards_list_secondary_tasks(stage.cards))
        end)
      _ ->
        Kanban.get_board!(socket.assigns.board.id).stages

    end

    current_board = Kanban.get_board!(socket.assigns.board.id)
    board = struct(current_board, stages: stages)

    showing_primaries = case radio_value do
      "task" -> true
      "subtask" -> false
      _ -> false
    end

    {:noreply, socket |> assign(board: board, showing_primaries: showing_primaries)}
  end

  def handle_event("distinct_task", %{"_target" => ["task_view"]}, socket) do
    {:noreply, socket}
  end


  def handle_event("search_task", %{"search-a" => text}, socket) do
    IO.inspect(text)

    stages =  Kanban.get_board!(socket.assigns.board.id).stages
    |> Enum.map(fn (%Kanban.Stage{} = stage) ->
      struct(stage, cards: cards_list_searched(stage.cards, text))
    end)

    current_board = Kanban.get_board!(socket.assigns.board.id)
    board = struct(current_board, stages: stages)

    new_stages = case socket.assigns.showing_primaries do
      true -> stages
          |> Enum.map(fn (%Kanban.Stage{} = stage) ->
            struct(stage, cards: cards_list_primary_tasks(stage.cards))
      end)

      _ ->
        stages
            |> Enum.map(fn (%Kanban.Stage{} = stage) ->
              struct(stage, cards: cards_list_secondary_tasks(stage.cards))
        end)

    end

    # current_board = Kanban.get_board!(socket.assigns.board.id)
    new_board = struct(board, stages: new_stages)

    {:noreply, socket
    |> assign(board: new_board)
  }
  end

  def handle_event("hide-card", %{"id" => id}, socket) do
    task = Monitoring.get_task!(id)
    Monitoring.hide_task(task)

    {:noreply, socket}
  end

  def handle_event("restore_tasks", params, socket) do
    list_ids = params |> Map.drop(["_csrf_token"]) |> Map.values
    Monitoring.restore_archived_tasks(list_ids)
    case length(list_ids) do
      0 ->
          {:noreply, socket |> assign(no_selected_hidden: true)}
      _ ->
        {:noreply, socket |> assign(show_hidden_modal: false) |>put_flash(:info, "Tâche(s) restaurée(s).") |> push_event("AnimateAlert", %{})}
    end
  end

  def handle_event("show_hidden_tasks", _params, socket) do
    # pro_id = socket.assigns.board.project.id
    # Monitoring.show_hidden_tasks(pro_id)
    {:noreply, socket |> assign(show_hidden_modal: true)}
  end

  def handle_event("close_hidden_modal", _params, socket) do
    {:noreply, socket |> assign(show_hidden_modal: false, no_selected_hidden: false)}
  end

  def handle_event("cancel-entry", %{"ref" => ref}, socket) do
    {:noreply, socket |> cancel_upload(:file, ref)}
  end

  def handle_event("change-comment", params, socket) do
    # IO.inspect params
    {:noreply, socket}
  end

  def handle_info({"hidden_subscription", [:task, :hidden], _}, socket) do
    board_id = socket.assigns.board.id
    pro_id = socket.assigns.board.project.id

    board = Kanban.get_board!(board_id)


    new_stages = case socket.assigns.showing_primaries do
      true -> board.stages
          |> Enum.map(fn (%Kanban.Stage{} = stage) ->
            struct(stage, cards: cards_list_primary_tasks(stage.cards))
      end)

      _ ->
        board.stages
            |> Enum.map(fn (%Kanban.Stage{} = stage) ->
              struct(stage, cards: cards_list_secondary_tasks(stage.cards))
        end)

    end

    # current_board = Kanban.get_board!(socket.assigns.board.id)
    new_board = struct(board, stages: new_stages)

    {:noreply, socket |> assign(board: new_board, hidden_tasks: Monitoring.list_hidden_tasks(pro_id))}
  end

  def handle_info({"hidden_subscription", [:tasks, :shown], _}, socket) do
    board_id = socket.assigns.board.id
    pro_id = socket.assigns.board.project.id

    board = Kanban.get_board!(board_id)

    new_stages = case socket.assigns.showing_primaries do
      true -> board.stages
          |> Enum.map(fn (%Kanban.Stage{} = stage) ->
            struct(stage, cards: cards_list_primary_tasks(stage.cards))
      end)

      _ ->
        board.stages
            |> Enum.map(fn (%Kanban.Stage{} = stage) ->
              struct(stage, cards: cards_list_secondary_tasks(stage.cards))
        end)

    end

    # current_board = Kanban.get_board!(socket.assigns.board.id)
    new_board = struct(board, stages: new_stages)

    {:noreply, socket |> assign(board: new_board, hidden_tasks: Monitoring.list_hidden_tasks(pro_id))}
  end

  def handle_event("switch-notif", %{}, socket) do
    notifs_length = socket.assigns.notifs |> length
    curr_user_id = socket.assigns.curr_user_id
    switch = if socket.assigns.show_notif do
              ids = socket.assigns.notifs
                    |> Enum.filter(fn(x) -> !(x.seen) end)
                    |> Enum.map(fn(x) -> x.id  end)
              Services.put_seen_some_notifs(ids)
                false
              else
                true
             end
    {:noreply, socket |> assign(show_notif: switch, notifs: Services.list_my_notifications_with_limit(curr_user_id, notifs_length))}
  end

  def handle_event("load-notifs", %{}, socket) do
    curr_user_id = socket.assigns.curr_user_id
    notifs_length = socket.assigns.notifs |> length
    {:noreply, socket |> assign(notifs: Services.list_my_notifications_with_limit(curr_user_id, notifs_length+4)) |> push_event("SpinTest", %{})}
  end

  def handle_event("cancel-notif", %{}, socket) do
    cancel = if socket.assigns.show_notif, do: false
    {:noreply, socket |> assign(show_notif: cancel)}
  end

  def handle_event("key_cancel", %{"key" => key}, socket) do

    show_task_modal = socket.assigns.show_task_modal
    show_secondary = socket.assigns.show_secondary
    show_plus_modal = socket.assigns.show_plus_modal
    show_modif_modal = socket.assigns.show_modif_modal
    show_comments_modal = socket.assigns.show_comments_modal
    show_modal = socket.assigns.show_modal
    show_hidden_modal = socket.assigns.show_hidden_modal


    s_task_modal = if (key == "Escape" and show_task_modal == true) ,do: false ,else: show_task_modal
    s_secondary = if (key == "Escape" and show_secondary == true) ,do: false ,else: show_secondary
    s_plus_modal = if (key == "Escape" and show_plus_modal == true) ,do: false ,else: show_plus_modal
    s_modif_modal = if (key == "Escape" and show_modif_modal == true) ,do: false ,else: show_modif_modal
    s_comments_modal = if (key == "Escape" and show_comments_modal == true) ,do: false ,else: show_comments_modal
    s_modal = if (key == "Escape" and show_modal == true) ,do: false ,else: show_modal
    s_hidden_modal = if (key == "Escape" and show_hidden_modal == true) ,do: false ,else: show_hidden_modal

    {:noreply, socket
               |> assign(show_task_modal: s_task_modal,
                          show_secondary: s_secondary,
                          show_plus_modal: s_plus_modal,
                          show_modif_modal: s_modif_modal,
                          show_comments_modal: s_comments_modal,
                          show_modal: s_modal,
                          show_hidden_modal: s_hidden_modal)}
  end

  def handle_event("show_alert_test", _params, socket) do
    {:noreply, socket |> put_flash(:info, "oiii")}
  end

  def handle_event("color_alert_test", _params, socket) do
    {:noreply, socket |> put_flash(:info, "iooo")|> push_event("AnimateAlert", %{})}
  end

  def handle_event("show-secondary", %{}, socket) do
    {:noreply, socket |> assign(show_secondary: true)}
  end

  def handle_info({SecondaryModalLive, :button_clicked, %{action: "cancel-secondary"}},socket) do
    {:noreply, assign(socket, show_secondary: false, secondary_changeset: Monitoring.change_task(%Task{}))}
  end

  def handle_event("send-comment", %{"comment" => params}, socket) do
    # IO.puts task_id
    # IO.puts poster_id
    # IO.puts content

    {entries, []} = uploaded_entries(socket, :file)
    IO.inspect entries

    case Monitoring.post_comment(params) do
      {:ok, result} ->
        consume_uploaded_entries(socket, :file, fn meta, entry ->
          ext = Path.extname(entry.client_name)
          file_name = Path.basename(entry.client_name, ext)
          dest = Path.join("priv/static/uploads", "#{file_name}#{entry.uuid}#{ext}")
          File.cp!(meta.path, dest)
        end)

        {entries, []} = uploaded_entries(socket, :file)

          urls = for entry <- entries do
            ext = Path.extname(entry.client_name)
            file_name = Path.basename(entry.client_name, ext)
            Routes.static_path(socket, "/uploads/#{file_name}#{entry.uuid}#{ext}")
          end

          Monitoring.update_comment_files(result, %{"file_urls" => urls})


        card_id = socket.assigns.card_with_comments.id
        nb_com = socket.assigns.com_nb
        {:ok, result} |> Monitoring.broadcast_com
        {:noreply, socket |> assign(comment_changeset:  Monitoring.change_comment(%Comment{}),card_with_comments: Kanban.get_card_for_comment_limit!(card_id, nb_com), com_nb: nb_com) |>push_event("updateScroll", %{})}

      {:error, %Ecto.Changeset{} = changeset} ->
        card_id = socket.assigns.card_with_comments.id
        nb_com = socket.assigns.com_nb
        {:noreply, socket |> assign(comment_changeset: changeset) |> push_event("updateScroll", %{})}

    end


  end

  def handle_event("update_card", %{"card" => card_attrs}, socket) do
    card = Kanban.get_card!(card_attrs["id"])
    # IO.inspect card_attrs
    # IO.inspect updated_stage
    # IO.puts "before"
    # IO.inspect card
    IO.inspect card_attrs
    case Kanban.update_card(card, card_attrs) do
      {:ok, _updated_card} ->
        updated_task = card.task_id |> Monitoring.get_task!
        updated_stage = card_attrs["stage_id"] |> Kanban.get_stage!
        task_attrs = %{"status_id" => updated_stage.status_id}
        IO.inspect Monitoring.update_task_status(updated_task, task_attrs)
        {:ok, real_task} = Monitoring.update_task_status(updated_task, task_attrs)
        {:ok, real_task} |> Monitoring.broadcast_status_change
        # IO.inspect real_task
        # IO.inspect Monitoring.get_task!(real_task.id)
        this_board = socket.assigns.board

        IO.puts "after"
        IO.inspect card
        IO.inspect Kanban.get_stage!(card.stage_id)

        #ADDING CHILD TASK TO ACHIEVED STAGE
        if Monitoring.is_a_child?(real_task) and Kanban.get_stage!(card.stage_id).status_id != 5 and real_task.status_id == 5 do
          curr_user_id = socket.assigns.curr_user_id
          Monitoring.update_mother_task_progression(real_task, curr_user_id)
        end

        #REMOVING CHILD TASK FROM ACHIEVED STAGE
        if Monitoring.is_a_child?(real_task) and Kanban.get_stage!(card.stage_id).status_id == 5 and real_task.status_id != 5  do
          Monitoring.substract_mother_task_progression_when_removing_child_from_achieved(real_task)
        end

        #ADDING PRIMARY TASK TO ACHIEVED STAGE
        if Monitoring.is_task_primary?(real_task) and Kanban.get_stage!(card.stage_id).status_id != 5 and real_task.status_id == 5 do
          project = socket.assigns.board.project
          Monitoring.add_progression_to_project(project)
        end

        #ADDING MOTHER TASK TO ACHIEVED STAGE
        if Monitoring.is_task_mother?(real_task) and Kanban.get_stage!(card.stage_id).status_id != 5 and real_task.status_id == 5 do
          Monitoring.achieve_children_tasks(real_task, socket.assigns.curr_user_id)
        end

        #REMOVING PRIMARY TASK FROM ACHIEVED STAGE
        if Monitoring.is_task_primary?(real_task) and Kanban.get_stage!(card.stage_id).status_id == 5 and real_task.status_id != 5 do
          project = socket.assigns.board.project
          Monitoring.substract_progression_to_project(project)
        end

        #REMOVING CHILD TASK FROM ACHIEVED STAGE
        if Monitoring.is_a_child?(real_task) and Kanban.get_stage!(card.stage_id).status_id == 5 and real_task.status_id != 5 do
          IO.puts "CHILD:"
          IO.inspect real_task
          IO.puts " AVEC PARENT:"
          rt_with_parent = Monitoring.get_task_with_parent!(real_task.id)
          IO.inspect rt_with_parent
          if rt_with_parent.parent.status_id == 5 do
            Monitoring.update_task(rt_with_parent.parent, %{"status_id" => real_task.status_id})
            Kanban.remove_mother_card_from_achieve(rt_with_parent.parent.card, %{"stage_id" => rt_with_parent.card.stage_id})
            project = socket.assigns.board.project
            Monitoring.substract_progression_to_project(project)
          end
        end


        #IF TASK IS UPDATED ON THE SAME STAGE
        post_socket = if Kanban.get_stage!(card.stage_id).status_id == real_task.status_id do

          socket
        else
          curr_user_id = socket.assigns.curr_user_id
          Services.send_notifs_to_admins_and_attributors(curr_user_id, "Tâche \"#{Monitoring.get_task_with_status!(real_task.id).title}\"
          du projet #{socket.assigns.board.project.title} mise dans \" #{Monitoring.get_task_with_status!(real_task.id).status.title} \" par #{Login.get_user!(curr_user_id).username}")

          socket |> put_flash(:info, "Tâche \"#{Monitoring.get_task_with_status!(real_task.id).title}\" mise dans \" #{Monitoring.get_task_with_status!(real_task.id).status.title} \" ") |> push_event("AnimateAlert", %{})
        end

        board = this_board

        new_stages = case socket.assigns.showing_primaries do
          true -> board.stages
              |> Enum.map(fn (%Kanban.Stage{} = stage) ->
                struct(stage, cards: cards_list_primary_tasks(stage.cards))
          end)

          _ ->
            board.stages
                |> Enum.map(fn (%Kanban.Stage{} = stage) ->
                  struct(stage, cards: cards_list_secondary_tasks(stage.cards))
            end)

        end

        # current_board = Kanban.get_board!(socket.assigns.board.id)
        new_board = struct(board, stages: new_stages)

        {:noreply, post_socket |> assign(board: new_board)}
        # {:noreply, update(socket, :board, fn _ -> Kanban.get_board!() end)}

      {:error, changeset} ->
        {:noreply, {:error, %{message: changeset.message}, socket}}
    end
  end

  # def handle_event("update_stage", %{"stage" => stage_attrs}, socket) do
  #   stage = Kanban.get_stage!(stage_attrs["id"])
  #
  #   case Kanban.update_stage(stage, stage_attrs) do
  #     {:ok, _updated_stage} ->
  #       this_board = socket.assigns.board
  #       {:noreply, update(socket, :board, fn _ -> Kanban.get_board!() end)}
  #
  #     {:error, changeset} ->
  #       {:noreply, {:error, %{message: changeset.message}, socket}}
  #   end
  # end

  def handle_info({Services, [:notifs, :sent], _}, socket) do
    curr_user_id = socket.assigns.curr_user_id
    length = socket.assigns.notifs |> length
    {:noreply, socket |> assign(notifs: Services.list_my_notifications_with_limit(curr_user_id, length))}
  end

  def handle_info({Monitoring, [:comment, :posted], _}, socket) do
    card_id = socket.assigns.card_with_comments.id
    nb_com = socket.assigns.com_nb
    {:noreply, socket
              |> assign(card_with_comments: Kanban.get_card_for_comment_limit!(card_id, nb_com), com_nb: nb_com)
              |> push_event("updateScroll", %{})}
  end

  def handle_info({Monitoring, [:task, :updated], _}, socket) do
    board_id = socket.assigns.board.id

    #for secondary task modal select form
    curr_user_id = socket.assigns.curr_user_id
    my_primary_tasks = Monitoring.list_primary_tasks(socket.assigns.board.project.id)
    list_primaries = my_primary_tasks |> Enum.map(fn (%Task{} = p) -> {p.title, p.id} end)

    board = Kanban.get_board!(board_id)

    new_stages = case socket.assigns.showing_primaries do
      true -> board.stages
          |> Enum.map(fn (%Kanban.Stage{} = stage) ->
            struct(stage, cards: cards_list_primary_tasks(stage.cards))
      end)

      _ ->
        board.stages
            |> Enum.map(fn (%Kanban.Stage{} = stage) ->
              struct(stage, cards: cards_list_secondary_tasks(stage.cards))
        end)

    end

    # current_board = Kanban.get_board!(socket.assigns.board.id)
    new_board = struct(board, stages: new_stages)

    {:noreply, assign(socket, board: new_board, primaries: list_primaries)}
  end

  def handle_info({Monitoring, [:status, :updated], _}, socket) do
    board_id = socket.assigns.board.id

    #for secondary task modal select form
    curr_user_id = socket.assigns.curr_user_id
    my_primary_tasks = Monitoring.list_primary_tasks(socket.assigns.board.project.id)
    list_primaries = my_primary_tasks |> Enum.map(fn (%Task{} = p) -> {p.title, p.id} end)

    board = Kanban.get_board!(board_id)

    new_stages = case socket.assigns.showing_primaries do
      true -> board.stages
          |> Enum.map(fn (%Kanban.Stage{} = stage) ->
            struct(stage, cards: cards_list_primary_tasks(stage.cards))
      end)

      _ ->
        board.stages
            |> Enum.map(fn (%Kanban.Stage{} = stage) ->
              struct(stage, cards: cards_list_secondary_tasks(stage.cards))
        end)

    end

    # current_board = Kanban.get_board!(socket.assigns.board.id)
    new_board = struct(board, stages: new_stages)

    {:noreply, assign(socket, board: new_board, primaries: list_primaries)}
  end

  def handle_info({Monitoring, [:project, :updated], _}, socket) do
    board_id = socket.assigns.board.id

    board = Kanban.get_board!(board_id)

    new_stages = case socket.assigns.showing_primaries do
      true -> board.stages
          |> Enum.map(fn (%Kanban.Stage{} = stage) ->
            struct(stage, cards: cards_list_primary_tasks(stage.cards))
      end)

      _ ->
        board.stages
            |> Enum.map(fn (%Kanban.Stage{} = stage) ->
              struct(stage, cards: cards_list_secondary_tasks(stage.cards))
        end)

    end

    # current_board = Kanban.get_board!(socket.assigns.board.id)
    new_board = struct(board, stages: new_stages)

    {:noreply, assign(socket, board: new_board)}
  end

  def handle_info({Monitoring, [:mother, :updated], _}, socket) do
    board_id = socket.assigns.board.id

    board = Kanban.get_board!(board_id)

    new_stages = case socket.assigns.showing_primaries do
      true -> board.stages
          |> Enum.map(fn (%Kanban.Stage{} = stage) ->
            struct(stage, cards: cards_list_primary_tasks(stage.cards))
      end)

      _ ->
        board.stages
            |> Enum.map(fn (%Kanban.Stage{} = stage) ->
              struct(stage, cards: cards_list_secondary_tasks(stage.cards))
        end)

    end

    # current_board = Kanban.get_board!(socket.assigns.board.id)
    new_board = struct(board, stages: new_stages)

    {:noreply, assign(socket, board: new_board)}
  end

  def handle_info({Monitoring, [:task, :created], _}, socket) do
    board_id = socket.assigns.board.id

    board = Kanban.get_board!(board_id)

    new_stages = case socket.assigns.showing_primaries do
      true -> board.stages
          |> Enum.map(fn (%Kanban.Stage{} = stage) ->
            struct(stage, cards: cards_list_primary_tasks(stage.cards))
      end)

      _ ->
        board.stages
            |> Enum.map(fn (%Kanban.Stage{} = stage) ->
              struct(stage, cards: cards_list_secondary_tasks(stage.cards))
        end)

    end

    # current_board = Kanban.get_board!(socket.assigns.board.id)
    new_board = struct(board, stages: new_stages)

    {:noreply, assign(socket, board: new_board)}
  end

  def handle_info({Kanban, [_, :updated], _}, socket) do
    proj_id = socket.assigns.pro_id
    project = Monitoring.get_project!(proj_id)

    board = Kanban.get_board!(project.board_id)

    new_stages = case socket.assigns.showing_primaries do
      true -> board.stages
          |> Enum.map(fn (%Kanban.Stage{} = stage) ->
            struct(stage, cards: cards_list_primary_tasks(stage.cards))
      end)

      _ ->
        board.stages
            |> Enum.map(fn (%Kanban.Stage{} = stage) ->
              struct(stage, cards: cards_list_secondary_tasks(stage.cards))
        end)

    end

    # current_board = Kanban.get_board!(socket.assigns.board.id)
    new_board = struct(board, stages: new_stages)

    {:noreply, assign(socket, board: new_board)}
  end

  def handle_info({Kanban, [_, :created], _}, socket) do
    proj_id = socket.assigns.pro_id
    project = Monitoring.get_project!(proj_id)
    my_primary_tasks = Monitoring.list_primary_tasks(proj_id)
    list_primaries = my_primary_tasks |> Enum.map(fn (%Task{} = p) -> {p.title, p.id} end)

    board = Kanban.get_board!(project.board_id)

    new_stages = case socket.assigns.showing_primaries do
      true -> board.stages
          |> Enum.map(fn (%Kanban.Stage{} = stage) ->
            struct(stage, cards: cards_list_primary_tasks(stage.cards))
      end)

      _ ->
        board.stages
            |> Enum.map(fn (%Kanban.Stage{} = stage) ->
              struct(stage, cards: cards_list_secondary_tasks(stage.cards))
        end)

    end

    # current_board = Kanban.get_board!(socket.assigns.board.id)
    new_board = struct(board, stages: new_stages)

    {:noreply, assign(socket, board: new_board, primaries: list_primaries)}
  end

  def handle_event("show_task_modal", %{}, socket) do
    {:noreply, socket |> assign(show_task_modal: true) |> push_event("blurBody", %{})}
  end

  def handle_event("show_comments_modal", %{"id" => id}, socket) do
    # IO.puts id
    # IO.puts "com modal showed"
    IO.puts id
    com_nb = 5
    card = Kanban.get_card_for_comment_limit!(id,com_nb)
    # card = ordered |> Enum.reverse
    {:noreply, socket |> assign(show_comments_modal: true, card_with_comments: card, com_nb: com_nb)
                      |> push_event("updateScroll", %{})}
  end

  def handle_event("load_comments", %{}, socket) do
    IO.puts "load"
    card_id = socket.assigns.card_with_comments.id
    nb_com = socket.assigns.com_nb + 5
    card = Kanban.get_card_for_comment_limit!(card_id,nb_com)
    {:noreply, socket |> assign(com_nb: nb_com, card_with_comments: card) |> push_event("SpinComment", %{})
    }
  end

  def handle_event("scroll-bot", %{}, socket) do
    # IO.puts "niditra scroll"
    {:noreply, socket |> push_event("updateScroll", %{})}
  end

  def handle_info({CommentsModalLive, :button_clicked, %{action: "cancel-comments"}},socket) do
    {:noreply, assign(socket, show_comments_modal: false)}
  end

  def handle_event("show_plus_modal", %{"id" => id}, socket) do
    card = Kanban.get_card_from_modal!(id)
    {:noreply, socket |> assign(show_plus_modal: true, card: card)}
  end

  def handle_event("show_modif_modal", %{"id" => id}, socket) do
    card = Kanban.get_card_from_modal!(id)
    {:noreply, socket |> assign(show_modif_modal: true, card: card)}
  end

  def handle_info({TaskModalLive, :button_clicked, %{action: "cancel"}},socket) do
    task_changeset = Monitoring.change_task(%Task{})
    {:noreply, assign(socket, show_task_modal: false, task_changeset: task_changeset )}
  end

  def handle_info({PlusModalLive, :button_clicked, %{action: "cancel-plus"}},socket) do
    # task_changeset = Monitoring.change_task(%Task{})
    {:noreply, assign(socket, show_plus_modal: false)}
  end

  def handle_info({ModifModalLive, :button_clicked, %{action: "cancel-modif"}},socket) do
    # task_changeset = Monitoring.change_task(%Task{})
    modif_changeset = Monitoring.change_task(%Task{})
    {:noreply, assign(socket, show_modif_modal: false, modif_changeset: modif_changeset)}
  end

  def handle_event("submit_secondary", %{"task" => params}, socket) do
    IO.puts "input"
    IO.inspect params

    parent_task = Monitoring.get_task!(params["parent_id"])
    IO.inspect parent_task

    parent_params = cond do
      is_nil(parent_task.contributor_id) and is_nil(params["contributor_id"]) -> %{"attributor_id" => socket.assigns.curr_user_id,
                                            "priority_id" => parent_task.priority_id
                                            }

      not is_nil(params["contributor_id"]) -> %{"attributor_id" => socket.assigns.curr_user_id,
      "contributor_id" => params["contributor_id"],
      "priority_id" => parent_task.priority_id
      }

      true -> %{"attributor_id" => socket.assigns.curr_user_id,
      "contributor_id" => parent_task.contributor_id,
      "priority_id" => parent_task.priority_id
      }

    end

    IO.puts "parent params"
    IO.inspect parent_params

    IO.puts "output"
    op_params = params |> Map.merge(parent_params)
    IO.inspect op_params


    case Monitoring.create_secondary_task(op_params) do
      {:ok, task} ->
        Monitoring.substract_mother_task_progression_when_creating_child(task)
        this_board = socket.assigns.board
        [head | _] = this_board.stages
        Kanban.create_card(%{name: task.title, stage_id: head.id ,task_id: task.id})
        #NOTIFY ATTRIBUTOR THAT A SECONDARY TASK HAS BEEN CREATED
        if not is_nil(task.contributor_id) do
          Services.send_notif_to_one(task.attributor_id, task.contributor_id, "Vous avez été assigné à la sous-tâche #{task.title} du projet #{Monitoring.get_project!(task.project_id).title}")
        end
        {:noreply, socket
        |> put_flash(:info, "La tâche secondaire #{Monitoring.get_task!(task.id).title} a bien été créee") |> push_event("AnimateAlert", %{})
        |> assign(show_secondary: false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket,secondary_changeset: changeset)}

    end
  end

  def handle_event("save", %{"task" => params}, socket) do
    # IO.inspect params
    case Monitoring.create_task_with_card(params) do
      {:ok, task} ->
        this_board = socket.assigns.board

        this_project = socket.assigns.board.project
        Monitoring.substract_project_progression_when_creating_primary(this_project)

        [head | _] = this_board.stages
        Kanban.create_card(%{name: task.title, stage_id: head.id ,task_id: task.id})
        #SEND NEW TASK NOTIFICATION TO ADMINS AND ATTRIBUTORS
        curr_user_id = socket.assigns.curr_user_id
        Services.send_notifs_to_admins_and_attributors(curr_user_id,"Tâche nouvellement créee du nom de #{task.title} par #{Login.get_user!(curr_user_id).username} dans le projet #{this_project.title}.")
        {:noreply, socket
        |> put_flash(:info, "La tâche #{Monitoring.get_task!(task.id).title} a bien été créee") |> push_event("AnimateAlert", %{})
        |> assign(show_task_modal: false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket,task_changeset: changeset)}
    end
  end

  def handle_event("update_task", %{"task" => params}, socket) do
    #progression to int
    IO.puts "OIIIIIIIIII"
    # IO.inspect params
    int_progression = params["progression"] |> Float.parse |> elem(0) |> trunc
    attrs = %{params | "progression" => int_progression}
          #UPDATING
    task = Monitoring.get_task!(params["task_id"])
    # IO.inspect params
    # IO.inspect task
    # IO.inspect Monitoring.update_task(task, params)
    case Monitoring.update_task(task, attrs) do
      {:ok, updated_task} ->
        # IO.inspect task
        # IO.inspect attrs
        {:ok, updated_task} |> Monitoring.broadcast_updated_task

        # IO.inspect {:ok, task}
        # IO.inspect {:ok, updated_task}

        if (is_nil task.contributor_id) and not (is_nil updated_task.contributor_id) do
          Services.send_notif_to_one(updated_task.attributor_id, updated_task.contributor_id, "#{Login.get_user!(updated_task.attributor_id).username} vous a assigné à la tâche #{updated_task.title}.")
        end
        {:noreply, socket |> put_flash(:info, "Tâche #{updated_task.title} mise à jour") |> assign(show_modif_modal: false) |> push_event("AnimateAlert", %{})}

      {:error, %Ecto.Changeset{} = changeset} ->
        # IO.inspect changeset
        # IO.inspect changeset.errors
        {:noreply, socket |> assign(modif_changeset: changeset)}
    end

  end

  def render(assigns) do
   ProjectView.render("board.html", assigns)
  end
end
