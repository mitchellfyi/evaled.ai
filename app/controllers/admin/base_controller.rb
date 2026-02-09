# frozen_string_literal: true
module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!

    layout "admin"

    private

    def require_admin!
      unless current_user&.has_role?(:admin) || current_user&.admin?
        redirect_to root_path, alert: "Access denied"
      end
    end
  end
end
