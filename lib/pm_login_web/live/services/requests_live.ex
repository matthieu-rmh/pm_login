defmodule PmLoginWeb.Services.RequestsLive do
  use Phoenix.LiveView
  alias PmLogin.Services
  alias PmLoginWeb.LiveComponent.ModalLive

  def mount(_params, %{"curr_user_id"=>curr_user_id}, socket) do
    Services.subscribe()
    Services.subscribe_to_request_topic()

    {:ok,
       socket
       |> assign(requests: Services.list_requests,
       show_modal: false, service_id: nil,curr_user_id: curr_user_id,show_notif: false, notifs: Services.list_my_notifications_with_limit(curr_user_id, 4)),
       layout: {PmLoginWeb.LayoutView, "admin_layout_live.html"}
       }
  end

  def handle_event("switch-seen", params, socket) do

    bool = case params["value"] do
    "on" -> true
      _ -> false
    end

    request = Services.get_request_with_user_id!(params["id"])
    Services.update_request_bool(request, %{"seen" => bool})

    text_vu = case bool do
      true -> "vue"
      _ -> "non vue"
    end
    curr_user_id = socket.assigns.curr_user_id
    notif_text = "La requête #{request.title} a été #{text_vu}"
    Services.send_notif_to_one(curr_user_id, request.active_client.user_id, notif_text)

    {:noreply, socket |> put_flash(:info, notif_text) |> push_event("AnimateAlert", %{})}
  end

  def handle_event("switch-ongoing", params, socket) do
    bool = case params["value"] do
    "on" -> true
      _ -> false
    end
    request = Services.get_request_with_user_id!(params["id"])
    Services.update_request_bool(request, %{"ongoing" => bool})

    text_encours = case bool do
      true -> "est en cours"
      _ -> "n\'est pas en cours"
    end
    curr_user_id = socket.assigns.curr_user_id
    notif_text = "La requête #{request.title} #{text_encours}"
    Services.send_notif_to_one(curr_user_id, request.active_client.user_id, notif_text)

    {:noreply, socket |> put_flash(:info, notif_text) |> push_event("AnimateAlert", %{})}
  end

  def handle_event("switch-done", params, socket) do
    bool = case params["value"] do
    "on" -> true
      _ -> false
    end
    request = Services.get_request_with_user_id!(params["id"])
    Services.update_request_bool(request, %{"done" => bool})

    text_accomplie = case bool do
      true -> "accomplie"
      _ -> "non accomplie"
    end
    curr_user_id = socket.assigns.curr_user_id

    notif_text = "Requête #{request.title} #{text_accomplie}"
    Services.send_notif_to_one(curr_user_id, request.active_client.user_id, notif_text)
    {:noreply, socket |> put_flash(:info, notif_text) |> push_event("AnimateAlert", %{})}
  end

  def handle_info({"request_topic", [:request, :updated], _}, socket) do
    {:noreply, socket |> assign(requests: Services.list_requests)}
  end

  def handle_info({"request_topic", [:request, :sent], _}, socket) do
    {:noreply, socket |> assign(requests: Services.list_requests)}
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
    {:noreply, socket |> assign(notifs: Services.list_my_notifications_with_limit(curr_user_id, notifs_length+4))}
  end

  def handle_event("cancel-notif", %{}, socket) do
    cancel = if socket.assigns.show_notif, do: false
    {:noreply, socket |> assign(show_notif: cancel)}
  end

  def handle_info({Services, [_, :deleted], _}, socket) do
    editors = Services.list_all_editors
    {:noreply, socket |> assign(editors: editors)}
  end

  def handle_info({Services, [:notifs, :sent], _}, socket) do
    curr_user_id = socket.assigns.curr_user_id
    length = socket.assigns.notifs |> length
    {:noreply, socket |> assign(notifs: Services.list_my_notifications_with_limit(curr_user_id, length))}
  end

  def render(assigns) do
   PmLoginWeb.ClientsRequestView.render("requests.html", assigns)
  end

  #del modal component

  def handle_info(
      {ModalLive, :button_clicked, %{action: "cancel-del"}},
      socket
    ) do
  {:noreply, assign(socket, show_modal: false)}
  end

  def handle_info(
      {ModalLive, :button_clicked, %{action: "del", param: service_id}},
      socket
    ) do
      editor = Services.get_editor!(service_id)
      Services.delete_editor(editor)
      # PmLoginWeb.UserController.archive(socket, user.id)
  {:noreply,
    socket
    |> put_flash(:info, "L'éditeur' #{editor.title} a bien été supprimé!")
    |> push_event("AnimateAlert", %{})
    |> assign(show_modal: false)
      }
  end

  def handle_event("go-del", %{"id" => id}, socket) do
    # Phoenix.LiveView.get_connect_info(socket)
    # put_session(socket, del_id: id)
    {:noreply, assign(socket, show_modal: true, service_id: id)}
  end

end