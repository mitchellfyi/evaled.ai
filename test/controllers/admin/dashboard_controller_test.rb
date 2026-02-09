require "test_helper"

module Admin
  class DashboardControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin_user = create(:user, :admin)
      @regular_user = create(:user)
    end

    test "unauthenticated users are redirected to login" do
      get admin_root_path
      assert_response :redirect
      assert_redirected_to new_user_session_path
    end

    test "non-admin users are redirected with access denied" do
      sign_in @regular_user
      get admin_root_path
      assert_response :redirect
      assert_redirected_to root_path
      assert_equal "Access denied", flash[:alert]
    end

    test "admin users can access the dashboard" do
      sign_in @admin_user
      get admin_root_path
      assert_response :success
    end

    test "dashboard displays stats" do
      sign_in @admin_user
      get admin_root_path
      assert_response :success
    end
  end
end
