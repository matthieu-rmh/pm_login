defmodule PmLoginWeb.LiveComponent.ModifModalLive do
  use Phoenix.LiveComponent
  import Phoenix.HTML.Form
  import PmLoginWeb.ErrorHelpers
  alias PmLoginWeb.Router.Helpers, as: Routes

  @defaults %{
    left_button: "Cancel",
    left_button_action: nil,
    left_button_param: nil,
    right_button: "OK",
    right_button_action: nil,
    right_button_param: nil
  }

  # render modal
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~L"""
    <div id="modal-<%= @id %>">
      <!-- Modal Background -->
      <div class="modal-container"
          phx-hook="ScrollLock">
        <div class="modal-inner-container">
          <div class="modal-card-task">
            <div class="modal-inner-card">
              <!-- Title -->
              <%= if @title != nil do %>
              <div class="modal-title" style="margin-bottom: 30px;">
                <%= @title %>
              </div>
              <% end %>

              <!-- Body -->
              <%= if @body != nil do %>
              <div class="modal-body">
                <%= @body %>
              </div>
              <% end %>

              <!-- MY FORM -->
              <div class="modal-body">
                <%= f = form_for @modif_changeset, "#", [phx_submit: :update_task, novalidate: :novalidate] %>
                <%= hidden_input f, :task_id,value: @card.task.id %>
                <!-- FIRST ROW -->
                  <div class="row">

                    <div class="column">
                      <div class="row">
                        <div class="column column-10">
                          <label>Nom: </label>
                          </div>
                          <div class="column column-65">
                          <%= @card.name %>
                          </div>
                      </div>
                    </div>

                    <div class="column">
                    <div class="row">
                      <div class="column column-40">
                        <label>Attributeur:</label>
                        </div>
                        <div class="column column-25">
                        <%= @card.task.attributor.username %>
                        </div>
                        <div class="column column-35">
                          <img class="profile-pic-mini" src="<%= Routes.static_path(@socket, "/#{@card.task.attributor.profile_picture}") %>" width="50"/>
                        </div>
                    </div>
                    </div>

                  </div>
                  <!-- END OF FIRST ROW -->

                    <!-- SECOND ROW -->
                      <div class="row">

                        <div class="column">

                              <%= label f, "Durée estimée (en heure(s)):" %>

                              <b><%= number_input f, :estimated_duration, style: "width: 70px", value: @card.task.estimated_duration %> h</b>
                              <%= error_tag f, :negative_estimated %>

                        </div>

                        <div class="column">
                          <label>Durée effectuée:</label>
                          <b><%= number_input f, :performed_duration, style: "width: 70px", value: @card.task.performed_duration %> h</b>
                          <%= error_tag f, :negative_performed%>
                        </div>


                      </div>
                      <!-- END OF SECOND ROW -->


                        <!-- THIRD ROW -->
                          <div class="row">

                            <div class="column">

                                  <%= label f, "Assigner contributeur" %>
                                  <%= select f, :contributor_id, @contributors, prompt: "Contributeurs:", selected: @card.task.contributor_id %>
                                  <%= error_tag f, :contributor_id %>

                            </div>

                            <div class="column">
                              <label>Priorité:</label>
                              <%= select f, :priority_id, @priorities, value: @card.task.priority_id %>
                            </div>

                          </div>
                          <!-- END OF THIRD ROW -->



                  <!-- FOURTH ROW -->
                  <div class="row">
                    <div class="column">
                      <%= label f, "Date de début" %>
                      <%= date_input f, :date_start, value: @card.task.date_start %>
                    </div>

                    <div class="column">
                      <%= label f, "Date finale" %>
                      <%= date_input f, :date_end, value: @card.task.date_end %>
                      <%= error_tag f, :dt_end_lt_start %>
                    </div>
                  </div>

                  <!-- END OF FOURTH ROW -->

                  <!-- FIFTH ROW -->
                    <div class="row" style="text-align:center;">
                    <%= label f, "Progression: ", style: "margin-top: 5px;" %>
                    <b><%= number_input f, :progression, value: @card.task.progression, style: "width: 70px; margin-left: 20px;" %> %</b>
                    <%= error_tag f, :invalid_progression %>
                    <%= error_tag f, :progression_not_int %>

                     </div>
                  <!-- -->

                  <!-- Buttons -->
                  <div class="modal-buttons">
                    <!-- Left Button -->
                    <button class="left-button"
                            type="button"
                            phx-click="left-button-click"
                            phx-target="#modal-<%= @id %>">
                      <div>
                        <%= @left_button %>
                      </div>
                    </button>
                      <div class="right-button">
                      <%= submit "Valider" %>
                      </div>
                  </div>



                </form>

              </div>


            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(socket) do
    {:ok, socket}
  end

  def update(%{id: _id} = assigns, socket) do
    {:ok, assign(socket, Map.merge(@defaults, assigns))}
  end

  # Fired when user clicks right button on modal
  def handle_event(
        "right-button-click",
        _params,
        %{
          assigns: %{
            right_button_action: right_button_action,
            right_button_param: right_button_param
          }
        } = socket
      ) do
    send(
      self(),
      {__MODULE__, :button_clicked, %{action: right_button_action, param: right_button_param}}
    )

    {:noreply, socket}
  end

  def handle_event(
        "left-button-click",
        _params,
        %{
          assigns: %{
            left_button_action: left_button_action,
            left_button_param: left_button_param
          }
        } = socket
      ) do
    send(
      self(),
      {__MODULE__, :button_clicked, %{action: left_button_action, param: left_button_param}}
    )

    {:noreply, socket}
  end
end