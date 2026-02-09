require "test_helper"

module Admin
  class UsersControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin_user = create(:user, :admin)
      @regular_user = create(:user)
      @target_user = create(:user, email: "target@example.com")
    end

    # Authentication tests
    test "unauthenticated users are redirected to login on index" do
      get admin_users_path
      assert_response :redirect
      assert_redirected_to new_user_session_path
    end

    test "unauthenticated users are redirected to login on show" do
      get admin_user_path(@target_user)
      assert_response :redirect
      assert_redirected_to new_user_session_path
    end

    test "non-admin users are redirected with access denied on index" do
      sign_in @regular_user
      get admin_users_path
      assert_response :redirect
      assert_redirected_to root_path
      assert_equal "Access denied", flash[:alert]
    end

    test "non-admin users are redirected with access denied on show" do
      sign_in @regular_user
      get admin_user_path(@target_user)
      assert_response :redirect
      assert_redirected_to root_path
      assert_equal "Access denied", flash[:alert]
    end

    # Admin access tests
    test "admin can access users index" do
      sign_in @admin_user
      get admin_users_path
      assert_response :success
    end

    test "admin can view user details" do
      sign_in @admin_user
      get admin_user_path(@target_user)
      assert_response :success
    end

    test "admin can access edit user page" do
      sign_in @admin_user
      get edit_admin_user_path(@target_user)
      assert_response :success
    end

    test "admin can update user" do
      sign_in @admin_user
      patch admin_user_path(@target_user), params: { user: { email: "updated@example.com" } }
      assert_response :redirect
      assert_redirected_to admin_user_path(@target_user)
      @target_user.reload
      assert_equal "updated@example.com", @target_user.email
    end

    test "admin can delete user" do
      sign_in @admin_user
      assert_difference("User.count", -1) do
        delete admin_user_path(@target_user)
      end
      assert_redirected_to admin_users_path
    end
  end
end
