# frozen_string_literal: true

require "test_helper"

class ScoreDecayCalculatorTest < ActiveSupport::TestCase
  setup do
    @agent = create(:agent)
  end

  # DECAY_RATES constant tests
  test "has slow decay rate" do
    assert ScoreDecayCalculator::DECAY_RATES.key?("slow")
    assert_equal 0.999, ScoreDecayCalculator::DECAY_RATES["slow"]
  end

  test "has standard decay rate" do
    assert ScoreDecayCalculator::DECAY_RATES.key?("standard")
    assert_equal 0.995, ScoreDecayCalculator::DECAY_RATES["standard"]
  end

  test "has fast decay rate" do
    assert ScoreDecayCalculator::DECAY_RATES.key?("fast")
    assert_equal 0.990, ScoreDecayCalculator::DECAY_RATES["fast"]
  end

  test "default rate is standard" do
    assert_equal "standard", ScoreDecayCalculator::DEFAULT_RATE
  end

  # decay_rate_factor tests
  test "decay_rate_factor returns correct rate for slow" do
    assert_equal 0.999, ScoreDecayCalculator.decay_rate_factor("slow")
  end

  test "decay_rate_factor returns correct rate for standard" do
    assert_equal 0.995, ScoreDecayCalculator.decay_rate_factor("standard")
  end

  test "decay_rate_factor returns correct rate for fast" do
    assert_equal 0.990, ScoreDecayCalculator.decay_rate_factor("fast")
  end

  test "decay_rate_factor returns default for unknown rate" do
    assert_equal 0.995, ScoreDecayCalculator.decay_rate_factor("unknown")
  end

  test "decay_rate_factor handles nil" do
    assert_equal 0.995, ScoreDecayCalculator.decay_rate_factor(nil)
  end

  # calculate_current_score tests
  test "calculate_current_score returns overall_score when score_at_eval is blank" do
    score = create(:agent_score, agent: @agent, overall_score: 85, score_at_eval: nil)

    result = ScoreDecayCalculator.calculate_current_score(score)

    assert_equal 85, result
  end

  test "calculate_current_score returns base score for recent evaluation" do
    score = create(:agent_score,
      agent: @agent,
      overall_score: 85,
      score_at_eval: 85,
      evaluated_at: Time.current,
      last_verified_at: Time.current,
      decay_rate: "standard"
    )

    result = ScoreDecayCalculator.calculate_current_score(score)

    # Should be very close to original score for recent evaluation
    assert_in_delta 85, result, 1.0
  end

  test "calculate_current_score decays over time" do
    score = create(:agent_score,
      agent: @agent,
      overall_score: 85,
      score_at_eval: 100,
      evaluated_at: 30.days.ago,
      last_verified_at: 30.days.ago,
      decay_rate: "standard"
    )

    result = ScoreDecayCalculator.calculate_current_score(score)

    # 30 days at 0.995 rate: 100 * 0.995^30 ≈ 86
    assert result < 100
    assert result > 80
  end

  test "calculate_current_score decays slower with slow rate" do
    score_slow = create(:agent_score,
      agent: @agent,
      overall_score: 100,
      score_at_eval: 100,
      evaluated_at: 30.days.ago,
      last_verified_at: 30.days.ago,
      decay_rate: "slow"
    )
    score_fast = create(:agent_score,
      agent: @agent,
      overall_score: 100,
      score_at_eval: 100,
      evaluated_at: 30.days.ago,
      last_verified_at: 30.days.ago,
      decay_rate: "fast"
    )

    result_slow = ScoreDecayCalculator.calculate_current_score(score_slow)
    result_fast = ScoreDecayCalculator.calculate_current_score(score_fast)

    assert result_slow > result_fast
  end

  test "calculate_current_score clamps to 0-100 range" do
    score = create(:agent_score,
      agent: @agent,
      overall_score: 100,
      score_at_eval: 100,
      evaluated_at: Time.current,
      decay_rate: "standard"
    )

    result = ScoreDecayCalculator.calculate_current_score(score)

    assert result >= 0
    assert result <= 100
  end

  # score_retention_percentage tests
  test "score_retention_percentage returns 100 when score_at_eval is blank" do
    score = create(:agent_score, agent: @agent, overall_score: 85, score_at_eval: nil)

    result = ScoreDecayCalculator.score_retention_percentage(score)

    assert_equal 100.0, result
  end

  test "score_retention_percentage returns 100 when score_at_eval is zero" do
    score = create(:agent_score, agent: @agent, overall_score: 0, score_at_eval: 0)

    result = ScoreDecayCalculator.score_retention_percentage(score)

    assert_equal 100.0, result
  end

  test "score_retention_percentage reflects decay" do
    score = create(:agent_score,
      agent: @agent,
      overall_score: 100,
      score_at_eval: 100,
      evaluated_at: 30.days.ago,
      last_verified_at: 30.days.ago,
      decay_rate: "standard"
    )

    result = ScoreDecayCalculator.score_retention_percentage(score)

    assert result < 100
    assert result > 0
  end

  # estimated_threshold_date tests
  test "estimated_threshold_date returns nil when score_at_eval is blank" do
    score = create(:agent_score, agent: @agent, score_at_eval: nil)

    result = ScoreDecayCalculator.estimated_threshold_date(score)

    assert_nil result
  end

  test "estimated_threshold_date returns nil when already below threshold" do
    score = create(:agent_score, agent: @agent, score_at_eval: 60)

    result = ScoreDecayCalculator.estimated_threshold_date(score, threshold: 70.0)

    assert_nil result
  end

  test "estimated_threshold_date returns nil when reference date is blank" do
    score = create(:agent_score,
      agent: @agent,
      score_at_eval: 100,
      evaluated_at: nil,
      last_verified_at: nil
    )

    result = ScoreDecayCalculator.estimated_threshold_date(score)

    assert_nil result
  end

  test "estimated_threshold_date returns future date for high score" do
    freeze_time do
      score = create(:agent_score,
        agent: @agent,
        score_at_eval: 100,
        evaluated_at: Time.current,
        last_verified_at: Time.current,
        decay_rate: "standard"
      )

      result = ScoreDecayCalculator.estimated_threshold_date(score, threshold: 70.0)

      assert result > Time.current
    end
  end

  test "estimated_threshold_date is sooner with fast decay" do
    freeze_time do
      score_slow = create(:agent_score,
        agent: @agent,
        score_at_eval: 100,
        evaluated_at: Time.current,
        last_verified_at: Time.current,
        decay_rate: "slow"
      )
      score_fast = create(:agent_score,
        agent: @agent,
        score_at_eval: 100,
        evaluated_at: Time.current,
        last_verified_at: Time.current,
        decay_rate: "fast"
      )

      result_slow = ScoreDecayCalculator.estimated_threshold_date(score_slow, threshold: 70.0)
      result_fast = ScoreDecayCalculator.estimated_threshold_date(score_fast, threshold: 70.0)

      assert result_fast < result_slow
    end
  end
end
