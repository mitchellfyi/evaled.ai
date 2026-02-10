# frozen_string_literal: true
module Builder
  class NotificationPreferencesController < BaseController
    before_action :set_agent
    before_action :authorize_agent

    def edit
      # Notification preferences are edited within the agent edit page
      redirect_to edit_builder_agent_path(@agent)
    end

    def update
      @notification_preference = @agent.notification_preferences.find_or_initialize_by(user: current_user)

      if @notification_preference.update(notification_params)
        redirect_to edit_builder_agent_path(@agent), notice: "Notification preferences updated."
      else
        render "builder/agents/edit", status: :unprocessable_content
      end
    end

    private

    def notification_params
      params.expect(notification_preference: [:score_changes, :new_eval_results,
        :comparison_mentions, :email_enabled])
    end
  end
end
