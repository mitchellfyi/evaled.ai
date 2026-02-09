require "test_helper"

module Admin
  class ApiKeysControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin_user = create(:user, :admin)
      @regular_user = create(:user)
      @api_key = create(:api_key, user: @regular_user)
    end

    # Authentication tests
    test "unauthenticated users are redirected to login on index" do
      get admin_api_keys_path
      assert_response :redirect
      assert_redirected_to new_user_session_path
    end

    test "non-admin users are redirected with access denied on index" do
      sign_in @regular_user
      get admin_api_keys_path
      assert_response :redirect
      assert_redirected_to root_path
      assert_equal "Access denied", flash[:alert]
    end

    test "non-admin users are redirected with access denied on destroy" do
      sign_in @regular_user
      delete admin_api_key_path(@api_key)
      assert_response :redirect
      assert_redirected_to root_path
      assert_equal "Access denied", flash[:alert]
    end

    # Admin access tests
    test "admin can access api keys index" do
      sign_in @admin_user
      get admin_api_keys_path
      assert_response :success
    end

    test "admin can revoke api key" do
      sign_in @admin_user
      assert_difference("ApiKey.count", -1) do
        delete admin_api_key_path(@api_key)
      end
      assert_redirected_to admin_api_keys_path
    end
  end
end
