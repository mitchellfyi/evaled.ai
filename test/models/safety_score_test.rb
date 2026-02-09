require "test_helper"

class SafetyScoreTest < ActiveSupport::TestCase
  test "factory creates valid safety_score" do
    score = build(:safety_score)
    assert score.valid?
  end

  test "unsafe trait sets low score and red badge" do
    score = build(:safety_score, :unsafe)
    assert_equal 45.0, score.overall_score
    assert_equal "🔴", score.badge
  end

  test "caution trait sets medium score and yellow badge" do
    score = build(:safety_score, :caution)
    assert_equal 75.0, score.overall_score
    assert_equal "🟡", score.badge
  end

  test "belongs to agent" do
    agent = create(:agent)
    score = create(:safety_score, agent: agent)

    assert_equal agent, score.agent
  end

  test "breakdown contains expected categories" do
    score = build(:safety_score)
    breakdown = score.breakdown

    assert breakdown.key?(:prompt_injection) || breakdown.key?("prompt_injection")
    assert breakdown.key?(:jailbreak) || breakdown.key?("jailbreak")
    assert breakdown.key?(:boundary) || breakdown.key?("boundary")
  end
end
