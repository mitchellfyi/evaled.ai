# frozen_string_literal: true

module Tier3
  class ScoringEngine
    # Combine telemetry signals into Tier 3 component score
    #
    # Tier 3 focuses on real-world performance telemetry:
    # - How well does the agent perform in production?
    # - Are there anomalies or concerning patterns?
    # - Is the agent cost-efficient?

    WEIGHTS = {
      telemetry: 0.60,
      anomaly_penalty: 0.25,
      reliability: 0.15
    }.freeze

    ANOMALY_PENALTIES = {
      "critical" => 15,
      "warning" => 5,
      "info" => 1
    }.freeze

    EXPIRY_DAYS = 7  # Tier 3 scores expire faster due to real-time nature

    BADGES = {
      excellent: "🟢",
      good: "🔵",
      fair: "🟡",
      poor: "🔴"
    }.freeze

    SCORE_THRESHOLDS = {
      excellent: 90,
      good: 75,
      fair: 60
    }.freeze

    def initialize(agent)
      @agent = agent
    end

    def evaluate
      telemetry_result = TelemetryScorer.new(@agent).analyze
      anomaly_result = AnomalyDetector.new(@agent).detect

      breakdown = build_breakdown(telemetry_result, anomaly_result)
      overall = calculate_overall_score(breakdown)
      badge = determine_badge(overall)

      AgentScore.create!(
        agent: @agent,
        tier: 3,
        overall_score: overall.round,
        breakdown: breakdown.merge(
          badge: badge,
          telemetry: telemetry_result,
          anomalies: anomaly_result
        ),
        evaluated_at: Time.current,
        expires_at: EXPIRY_DAYS.days.from_now
      )
    end

    private

    def build_breakdown(telemetry, anomalies)
      {
        telemetry_score: telemetry[:score],
        anomaly_penalty: calculate_anomaly_penalty(anomalies),
        reliability_score: calculate_reliability_score(telemetry, anomalies),
        health_status: anomalies[:health_status],
        summary: build_summary(telemetry, anomalies)
      }
    end

    def calculate_overall_score(breakdown)
      base_score = breakdown[:telemetry_score] * WEIGHTS[:telemetry]
      penalty = breakdown[:anomaly_penalty] * WEIGHTS[:anomaly_penalty]
      reliability = breakdown[:reliability_score] * WEIGHTS[:reliability]

      # Anomaly penalty reduces the score
      score = base_score + reliability - penalty

      [[score, 100].min, 0].max.round(2)
    end

    def calculate_anomaly_penalty(anomaly_result)
      anomaly_result[:anomalies].sum do |anomaly|
        ANOMALY_PENALTIES[anomaly[:severity]] || 0
      end
    end

    def calculate_reliability_score(telemetry, anomalies)
      base_score = 100

      # Penalize based on health status
      case anomalies[:health_status]
      when "degraded"
        base_score -= 40
      when "at_risk"
        base_score -= 20
      when "stable"
        base_score -= 5
      end

      # Bonus for excellent success rate
      base_score += 10 if telemetry.dig(:success_rate, :grade) == "excellent"

      # Bonus for excellent latency
      base_score += 10 if telemetry.dig(:latency, :grade) == "excellent"

      # Penalty for poor cost efficiency
      base_score -= 10 if telemetry.dig(:cost_efficiency, :efficiency_grade) == "poor"

      [[base_score, 100].min, 0].max
    end

    def determine_badge(score)
      if score >= SCORE_THRESHOLDS[:excellent]
        BADGES[:excellent]
      elsif score >= SCORE_THRESHOLDS[:good]
        BADGES[:good]
      elsif score >= SCORE_THRESHOLDS[:fair]
        BADGES[:fair]
      else
        BADGES[:poor]
      end
    end

    def build_summary(telemetry, anomalies)
      issues = []
      strengths = []

      # Analyze telemetry
      if telemetry.dig(:success_rate, :grade) == "excellent"
        strengths << "Excellent success rate (#{telemetry.dig(:success_rate, :rate)}%)"
      elsif telemetry.dig(:success_rate, :grade) == "poor"
        issues << "Low success rate (#{telemetry.dig(:success_rate, :rate)}%)"
      end

      if telemetry.dig(:latency, :grade) == "excellent"
        strengths << "Fast response times (p95: #{telemetry.dig(:latency, :p95)}ms)"
      elsif telemetry.dig(:latency, :grade) == "poor"
        issues << "High latency (p95: #{telemetry.dig(:latency, :p95)}ms)"
      end

      if telemetry.dig(:cost_efficiency, :efficiency_grade) == "excellent"
        strengths << "Cost efficient ($#{telemetry.dig(:cost_efficiency, :cost_per_request)}/req)"
      elsif telemetry.dig(:cost_efficiency, :efficiency_grade) == "poor"
        issues << "High costs ($#{telemetry.dig(:cost_efficiency, :cost_per_request)}/req)"
      end

      # Analyze anomalies
      if anomalies[:critical_count].positive?
        issues << "#{anomalies[:critical_count]} critical anomalies detected"
      end

      if anomalies[:warning_count] > 2
        issues << "#{anomalies[:warning_count]} warning-level anomalies"
      end

      if anomalies[:health_status] == "healthy"
        strengths << "No anomalies detected"
      end

      {
        issues: issues,
        strengths: strengths,
        recommendation: generate_recommendation(issues, strengths, anomalies)
      }
    end

    def generate_recommendation(issues, strengths, anomalies)
      if issues.empty? && anomalies[:health_status] == "healthy"
        "Agent is performing well. Continue monitoring."
      elsif anomalies[:critical_count].positive?
        "Critical issues detected. Immediate investigation recommended."
      elsif issues.size > strengths.size
        "Performance concerns identified. Review telemetry data for optimization opportunities."
      else
        "Generally healthy with some areas for improvement. Monitor trends."
      end
    end
  end
end
