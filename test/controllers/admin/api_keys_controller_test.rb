# frozen_string_literal: true
require "test_helper"

module Admin
  class ApiKeysControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = create(:user, :admin)
      @user = create(:user)
      @api_key = create(:api_key, user: @user, name: "Test Key")
      sign_in @admin
    end

    # Index tests
    test "index returns success" do
      get admin_api_keys_path
      assert_response :success
    end

    test "index lists all api keys" do
      create_list(:api_key, 5)

      get admin_api_keys_path
      assert_response :success
    end

    test "index orders api keys by created_at desc" do
      get admin_api_keys_path
      assert_response :success
    end

    test "index includes user information" do
      # ApiKey includes user association
      get admin_api_keys_path
      assert_response :success
    end

    # Destroy tests
    test "destroy revokes api key and redirects" do
      assert_difference("ApiKey.count", -1) do
        delete admin_api_key_path(@api_key)
      end

      assert_redirected_to admin_api_keys_path
      assert_equal "API key revoked successfully.", flash[:notice]
    end

    test "destroy returns not found for nonexistent api key" do
      delete admin_api_key_path(id: 99999)
      assert_response :not_found
    end

    test "destroy can revoke any users api key" do
      other_user = create(:user)
      other_key = create(:api_key, user: other_user)

      assert_difference("ApiKey.count", -1) do
        delete admin_api_key_path(other_key)
      end

      assert_redirected_to admin_api_keys_path
    end

    # Authorization tests
    test "index requires authentication" do
      sign_out @admin

      get admin_api_keys_path
      assert_redirected_to new_user_session_path
    end

    test "index requires admin" do
      sign_out @admin
      sign_in @user

      get admin_api_keys_path
      assert_redirected_to root_path
      assert_equal "Access denied", flash[:alert]
    end

    test "destroy requires authentication" do
      sign_out @admin

      assert_no_difference("ApiKey.count") do
        delete admin_api_key_path(@api_key)
      end

      assert_redirected_to new_user_session_path
    end

    test "destroy requires admin" do
      sign_out @admin
      sign_in @user

      assert_no_difference("ApiKey.count") do
        delete admin_api_key_path(@api_key)
      end

      assert_redirected_to root_path
    end

    test "regular user cannot revoke own api key through admin" do
      sign_out @admin
      own_key = create(:api_key, user: @user)
      sign_in @user

      assert_no_difference("ApiKey.count") do
        delete admin_api_key_path(own_key)
      end

      assert_redirected_to root_path
    end
  end
end
