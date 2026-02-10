# frozen_string_literal: true
module Builder
  class BaseController < ApplicationController
    before_action :authenticate_user!

    private

    def set_agent
      @agent = Agent.find_by!(slug: params[:agent_id] || params[:id])
    end

    def authorize_agent
      unless @agent.claimed_by_user == current_user
        redirect_to builder_root_path, alert: "You don't have permission to manage this agent."
      end
    end
  end
end
