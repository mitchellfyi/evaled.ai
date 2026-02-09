# frozen_string_literal: true
require "test_helper"

class AgentScoreTest < ActiveSupport::TestCase
  test "factory creates valid agent_score" do
    score = build(:agent_score)
    assert score.valid?
  end

  test "requires tier" do
    score = build(:agent_score, tier: nil)
    refute score.valid?
    assert_includes score.errors[:tier], "can't be blank"
  end

  test "requires overall_score" do
    score = build(:agent_score, overall_score: nil)
    refute score.valid?
    assert_includes score.errors[:overall_score], "can't be blank"
  end

  test "overall_score must be within 0-100 range" do
    below_zero = build(:agent_score, overall_score: -1)
    above_hundred = build(:agent_score, overall_score: 101)
    valid_low = build(:agent_score, overall_score: 0)
    valid_high = build(:agent_score, overall_score: 100)

    refute below_zero.valid?
    refute above_hundred.valid?
    assert valid_low.valid?
    assert valid_high.valid?
  end

  test "tier0 scope returns only tier 0 scores" do
    tier0 = create(:agent_score, tier: 0)
    tier1 = create(:agent_score, tier: 1)

    result = AgentScore.tier0
    assert_includes result, tier0
    refute_includes result, tier1
  end

  test "current scope returns only non-expired scores" do
    current = create(:agent_score, expires_at: 1.day.from_now)
    expired = create(:agent_score, expires_at: 1.day.ago)

    result = AgentScore.current
    assert_includes result, current
    refute_includes result, expired
  end

  test "latest scope orders by evaluated_at descending" do
    old = create(:agent_score, evaluated_at: 60.days.ago)
    recent = create(:agent_score, evaluated_at: 30.days.ago)
    newest = create(:agent_score, evaluated_at: 1.day.ago)

    result = AgentScore.latest.to_a
    assert_equal [newest, recent, old], result
  end

  test "needing_reverification scope returns scores past scheduled date" do
    needs_reverify = create(:agent_score, next_eval_scheduled_at: 1.day.ago)
    not_scheduled = create(:agent_score, next_eval_scheduled_at: nil)
    future = create(:agent_score, next_eval_scheduled_at: 1.day.from_now)

    result = AgentScore.needing_reverification
    assert_includes result, needs_reverify
    assert_includes result, not_scheduled
    refute_includes result, future
  end

  test "decay_rate enum works correctly" do
    slow = build(:agent_score, decay_rate: "slow")
    standard = build(:agent_score, decay_rate: "standard")
    fast = build(:agent_score, decay_rate: "fast")

    assert slow.slow?
    assert standard.standard?
    assert fast.fast?
  end

  test "record_evaluation! updates tracking fields" do
    score = create(:agent_score,
      overall_score: 90,
      score_at_eval: 80,
      last_verified_at: 30.days.ago,
      next_eval_scheduled_at: 1.day.ago
    )

    score.record_evaluation!

    assert_equal 90, score.score_at_eval
    assert_in_delta Time.current.to_i, score.last_verified_at.to_i, 5
    assert_nil score.next_eval_scheduled_at
  end

  test "belongs to agent" do
    agent = create(:agent)
    score = create(:agent_score, agent: agent)

    assert_equal agent, score.agent
  end
end
