# frozen_string_literal: true

require "test_helper"

module Tier3
  class ScoringEngineTest < ActiveSupport::TestCase
    setup do
      @agent = create(:agent)
      @engine = ScoringEngine.new(@agent)
    end

    test "evaluate creates an AgentScore record" do
      assert_difference -> { AgentScore.count }, 1 do
        @engine.evaluate
      end
    end

    test "evaluate creates score with tier 3" do
      score = @engine.evaluate

      assert_equal 3, score.tier
    end

    test "evaluate creates score with overall_score between 0 and 100" do
      score = @engine.evaluate

      assert score.overall_score >= 0
      assert score.overall_score <= 100
    end

    test "evaluate creates score with breakdown" do
      score = @engine.evaluate

      assert score.breakdown.present?
      assert score.breakdown.key?("telemetry_score")
      assert score.breakdown.key?("anomaly_penalty")
      assert score.breakdown.key?("reliability_score")
      assert score.breakdown.key?("health_status")
      assert score.breakdown.key?("summary")
    end

    test "evaluate sets evaluated_at" do
      score = @engine.evaluate

      assert score.evaluated_at.present?
      assert score.evaluated_at <= Time.current
    end

    test "evaluate sets expires_at in the future" do
      score = @engine.evaluate

      assert score.expires_at.present?
      assert score.expires_at > Time.current
    end

    test "expires_at is 7 days from evaluation" do
      freeze_time do
        score = @engine.evaluate
        expected_expiry = 7.days.from_now

        assert_in_delta expected_expiry.to_i, score.expires_at.to_i, 1
      end
    end

    test "breakdown includes badge" do
      score = @engine.evaluate

      assert score.breakdown.key?("badge")
      valid_badges = %w[🟢 🔵 🟡 🔴]
      assert_includes valid_badges, score.breakdown["badge"]
    end

    test "breakdown includes telemetry data" do
      score = @engine.evaluate

      assert score.breakdown.key?("telemetry")
      telemetry = score.breakdown["telemetry"]
      assert telemetry.key?("score")
      assert telemetry.key?("success_rate")
      assert telemetry.key?("latency")
    end

    test "breakdown includes anomaly data" do
      score = @engine.evaluate

      assert score.breakdown.key?("anomalies")
      anomalies = score.breakdown["anomalies"]
      assert anomalies.key?("anomalies")
      assert anomalies.key?("anomaly_count")
      assert anomalies.key?("health_status")
    end

    test "summary includes issues and strengths" do
      score = @engine.evaluate

      summary = score.breakdown["summary"]
      assert summary.key?("issues")
      assert summary.key?("strengths")
      assert summary.key?("recommendation")
    end

    test "score belongs to the correct agent" do
      score = @engine.evaluate

      assert_equal @agent.id, score.agent_id
    end

    test "health_status reflects anomaly analysis" do
      score = @engine.evaluate

      valid_statuses = %w[healthy stable at_risk degraded]
      assert_includes valid_statuses, score.breakdown["health_status"]
    end

    test "anomaly penalty is non-negative" do
      score = @engine.evaluate

      assert score.breakdown["anomaly_penalty"] >= 0
    end

    test "reliability score is between 0 and 100" do
      score = @engine.evaluate

      assert score.breakdown["reliability_score"] >= 0
      assert score.breakdown["reliability_score"] <= 100
    end

    test "weights sum to 1.0" do
      weights = ScoringEngine::WEIGHTS.values.sum

      assert_in_delta 1.0, weights, 0.001
    end

    test "multiple evaluations create separate records" do
      score1 = @engine.evaluate
      score2 = @engine.evaluate

      assert_not_equal score1.id, score2.id
    end
  end
end
