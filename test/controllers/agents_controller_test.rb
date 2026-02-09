require "test_helper"

class AgentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @agent = create(:agent, :published, :with_score, slug: "test-agent", name: "Test Agent")
  end

  test "index returns success" do
    get agents_path
    assert_response :success
  end

  test "index shows published agents" do
    published = create(:agent, :published, name: "Published Agent")
    create(:agent, published: false, name: "Hidden Agent")

    get agents_path
    assert_response :success
  end

  test "index filters by category" do
    create(:agent, :published, category: "coding", name: "Coding Agent")
    create(:agent, :published, category: "research", name: "Research Agent")

    get agents_path(category: "coding")
    assert_response :success
  end

  test "index filters by min_score" do
    create(:agent, :published, score: 90, name: "High Score Agent")
    create(:agent, :published, score: 50, name: "Low Score Agent")

    get agents_path(min_score: 80)
    assert_response :success
  end

  test "show returns success for published agent" do
    get agent_path(@agent)
    assert_response :success
  end

  test "show returns not found for unpublished agent" do
    unpublished = create(:agent, published: false, slug: "hidden")

    get agent_path(unpublished)
    assert_response :not_found
  end

  test "compare returns success" do
    agent1 = create(:agent, :published, slug: "agent-1")
    agent2 = create(:agent, :published, slug: "agent-2")

    get compare_path(agents: "agent-1,agent-2")
    assert_response :success
  end
end
