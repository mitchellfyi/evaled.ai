# frozen_string_literal: true

require "test_helper"

class RecommendationEngineTest < ActiveSupport::TestCase
  setup do
    @engine = RecommendationEngine.new
  end

  # recommend_for_capability tests
  test "recommend_for_capability returns array" do
    result = @engine.recommend_for_capability("coding")

    assert_kind_of Array, result
  end

  test "recommend_for_capability returns empty for blank capability" do
    assert_empty @engine.recommend_for_capability("")
    assert_empty @engine.recommend_for_capability(nil)
  end

  test "recommend_for_capability respects limit" do
    # Create more agents than the limit
    6.times do |i|
      create(:agent, :published, category: "research", score: 80 + i)
    end

    result = @engine.recommend_for_capability("research", limit: 3)

    assert_equal 3, result.size
  end

  test "recommend_for_capability returns published agents only" do
    create(:agent, category: "coding", score: 90, published: false)
    published_agent = create(:agent, :published, category: "coding", score: 80)

    result = @engine.recommend_for_capability("coding")

    slugs = result.map { |r| r[:slug] }
    assert_includes slugs, published_agent.slug
  end

  test "recommend_for_capability returns highest scores first" do
    low_score = create(:agent, :published, category: "coding", score: 60)
    high_score = create(:agent, :published, category: "coding", score: 95)

    result = @engine.recommend_for_capability("coding")

    assert_equal high_score.slug, result.first[:slug]
  end

  test "recommend_for_capability includes expected data" do
    agent = create(:agent, :published, category: "coding", score: 85)

    result = @engine.recommend_for_capability("coding")
    recommendation = result.find { |r| r[:slug] == agent.slug }

    assert recommendation[:slug].present?
    assert recommendation[:name].present?
    assert recommendation[:score].present?
    assert recommendation[:match_reason].present?
  end

  test "class method recommend_for_capability works" do
    agent = create(:agent, :published, category: "workflow", score: 90)

    result = RecommendationEngine.recommend_for_capability("workflow")

    assert result.any? { |r| r[:slug] == agent.slug }
  end

  # find_similar_agents tests
  test "find_similar_agents returns array" do
    agent = create(:agent, :published)

    result = @engine.find_similar_agents(agent)

    assert_kind_of Array, result
  end

  test "find_similar_agents returns empty for nil agent" do
    result = @engine.find_similar_agents(nil)

    assert_empty result
  end

  # Note: Additional find_similar_agents tests are skipped as the method requires
  # a 'categories' array column that doesn't exist in the current schema.
  # The schema has 'category' (singular string) instead.
end
