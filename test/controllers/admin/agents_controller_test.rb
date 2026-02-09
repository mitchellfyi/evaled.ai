require "test_helper"

module Admin
  class AgentsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin_user = create(:user, :admin)
      @regular_user = create(:user)
      @agent = create(:agent, name: "Test Agent", slug: "test-agent")
    end

    # Authentication tests
    test "unauthenticated users are redirected to login on index" do
      get admin_agents_path
      assert_response :redirect
      assert_redirected_to new_user_session_path
    end

    test "unauthenticated users are redirected to login on show" do
      get admin_agent_path(@agent)
      assert_response :redirect
      assert_redirected_to new_user_session_path
    end

    test "non-admin users are redirected with access denied on index" do
      sign_in @regular_user
      get admin_agents_path
      assert_response :redirect
      assert_redirected_to root_path
      assert_equal "Access denied", flash[:alert]
    end

    test "non-admin users are redirected with access denied on show" do
      sign_in @regular_user
      get admin_agent_path(@agent)
      assert_response :redirect
      assert_redirected_to root_path
      assert_equal "Access denied", flash[:alert]
    end

    # Admin access tests
    test "admin can access agents index" do
      sign_in @admin_user
      get admin_agents_path
      assert_response :success
    end

    test "admin can view agent details" do
      sign_in @admin_user
      get admin_agent_path(@agent)
      assert_response :success
    end

    test "admin can access edit agent page" do
      sign_in @admin_user
      get edit_admin_agent_path(@agent)
      assert_response :success
    end

    test "admin can update agent" do
      sign_in @admin_user
      patch admin_agent_path(@agent), params: { agent: { name: "Updated Agent" } }
      assert_response :redirect
      assert_redirected_to admin_agent_path(@agent)
      @agent.reload
      assert_equal "Updated Agent", @agent.name
    end

    test "admin can delete agent" do
      sign_in @admin_user
      assert_difference("Agent.count", -1) do
        delete admin_agent_path(@agent)
      end
      assert_redirected_to admin_agents_path
    end
  end
end
