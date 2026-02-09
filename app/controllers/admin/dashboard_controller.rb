# frozen_string_literal: true
module Admin
  class DashboardController < BaseController
    def index
      @stats = {
        users_count: User.count,
        agents_count: Agent.count,
        api_keys_count: ApiKey.count
      }
    end
  end
end
