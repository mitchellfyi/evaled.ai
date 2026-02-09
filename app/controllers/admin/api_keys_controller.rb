# frozen_string_literal: true
module Admin
  class ApiKeysController < BaseController
    def index
      @api_keys = ApiKey.includes(:user).order(created_at: :desc)
    end

    def destroy
      @api_key = ApiKey.find(params[:id])
      @api_key.destroy
      redirect_to admin_api_keys_path, notice: "API key revoked successfully."
    end
  end
end
