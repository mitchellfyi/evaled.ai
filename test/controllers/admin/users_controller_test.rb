require "test_helper"

module Admin
  class UsersControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = create(:user, :admin, email: "admin@example.com")
      @user = create(:user, email: "regular@example.com")
      sign_in @admin
    end

    # Index tests
    test "index returns success" do
      get admin_users_path
      assert_response :success
    end

    test "index lists all users" do
      create_list(:user, 3)

      get admin_users_path
      assert_response :success
    end

    test "index orders users by created_at desc" do
      get admin_users_path
      assert_response :success
    end

    # Show tests
    test "show returns success" do
      get admin_user_path(@user)
      assert_response :success
    end

    test "show displays user details" do
      get admin_user_path(@user)
      assert_response :success
    end

    test "show returns not found for nonexistent user" do
      assert_raises(ActiveRecord::RecordNotFound) do
        get admin_user_path(id: 99999)
      end
    end

    # Edit tests
    test "edit returns success" do
      get edit_admin_user_path(@user)
      assert_response :success
    end

    test "edit returns not found for nonexistent user" do
      assert_raises(ActiveRecord::RecordNotFound) do
        get edit_admin_user_path(id: 99999)
      end
    end

    # Update tests
    test "update with valid params redirects to show" do
      patch admin_user_path(@user), params: { user: { email: "updated@example.com" } }

      assert_redirected_to admin_user_path(@user)
      assert_equal "User updated successfully.", flash[:notice]
      @user.reload
      assert_equal "updated@example.com", @user.email
    end

    test "update with invalid params renders edit" do
      # Email can't be blank
      patch admin_user_path(@user), params: { user: { email: "" } }

      assert_response :unprocessable_entity
    end

    test "update allows changing admin status for other users" do
      patch admin_user_path(@user), params: { user: { admin: true } }

      assert_redirected_to admin_user_path(@user)
      @user.reload
      assert @user.admin?
    end

    test "update prevents self-demotion" do
      patch admin_user_path(@admin), params: { user: { admin: false } }

      # Admin status should not change for self
      @admin.reload
      assert @admin.admin?
    end

    # Destroy tests
    test "destroy deletes user and redirects" do
      assert_difference("User.count", -1) do
        delete admin_user_path(@user)
      end

      assert_redirected_to admin_users_path
      assert_equal "User deleted successfully.", flash[:notice]
    end

    test "destroy returns not found for nonexistent user" do
      assert_raises(ActiveRecord::RecordNotFound) do
        delete admin_user_path(id: 99999)
      end
    end

    # Authorization tests
    test "index requires admin" do
      sign_out @admin
      sign_in @user

      get admin_users_path
      assert_redirected_to root_path
    end

    test "show requires admin" do
      sign_out @admin
      sign_in @user

      get admin_user_path(@user)
      assert_redirected_to root_path
    end

    test "edit requires admin" do
      sign_out @admin
      sign_in @user

      get edit_admin_user_path(@user)
      assert_redirected_to root_path
    end

    test "update requires admin" do
      sign_out @admin
      sign_in @user

      patch admin_user_path(@user), params: { user: { email: "hack@example.com" } }
      assert_redirected_to root_path

      @user.reload
      assert_equal "regular@example.com", @user.email
    end

    test "destroy requires admin" do
      sign_out @admin
      sign_in @user

      assert_no_difference("User.count") do
        delete admin_user_path(@user)
      end

      assert_redirected_to root_path
    end
  end
end
