# frozen_string_literal: true

module Tier3
  class TelemetryScorer
    # Compute performance scores from aggregated telemetry data
    #
    # Analyzes:
    # - Success rate calculation
    # - Latency percentiles (p50, p95, p99)
    # - Error rate trends
    # - Cost efficiency metrics

    LATENCY_THRESHOLDS = {
      excellent: { p50: 100, p95: 500, p99: 1000 },   # milliseconds
      good: { p50: 250, p95: 1000, p99: 2000 },
      acceptable: { p50: 500, p95: 2000, p99: 5000 }
    }.freeze

    SUCCESS_RATE_THRESHOLDS = {
      excellent: 99.5,
      good: 98.0,
      acceptable: 95.0
    }.freeze

    COST_EFFICIENCY_WEIGHTS = {
      cost_per_request: 0.4,
      cost_per_success: 0.3,
      cost_trend: 0.3
    }.freeze

    def initialize(agent)
      @agent = agent
      @telemetry_data = nil
    end

    def analyze
      @telemetry_data = fetch_telemetry_data

      {
        score: calculate_overall_score,
        success_rate: analyze_success_rate,
        latency: analyze_latency,
        error_trends: analyze_error_trends,
        cost_efficiency: analyze_cost_efficiency,
        analyzed_at: Time.current.iso8601
      }
    end

    private

    def fetch_telemetry_data
      # Fetch telemetry from agent's recorded metrics
      # In production, this would query a time-series database or metrics store
      {
        requests: fetch_request_metrics,
        latencies: fetch_latency_samples,
        errors: fetch_error_history,
        costs: fetch_cost_data
      }
    end

    def fetch_request_metrics
      # Placeholder: would fetch from actual telemetry store
      {
        total: 10_000,
        successful: 9_850,
        failed: 150,
        period_hours: 24
      }
    end

    def fetch_latency_samples
      # Placeholder: would fetch actual latency percentiles
      {
        p50: 120,
        p95: 450,
        p99: 890,
        samples_count: 10_000
      }
    end

    def fetch_error_history
      # Placeholder: would fetch error trends over time
      [
        { hour: 0, count: 5 },
        { hour: 1, count: 7 },
        { hour: 2, count: 4 },
        { hour: 3, count: 15 }, # spike
        { hour: 4, count: 6 }
      ]
    end

    def fetch_cost_data
      # Placeholder: would fetch cost metrics
      {
        total_cost: 125.50,
        cost_per_request: 0.0125,
        cost_trend: -0.05 # 5% decrease
      }
    end

    def calculate_overall_score
      components = [
        { weight: 0.35, score: success_rate_score },
        { weight: 0.30, score: latency_score },
        { weight: 0.20, score: error_trend_score },
        { weight: 0.15, score: cost_efficiency_score }
      ]

      components.sum { |c| c[:weight] * c[:score] }.round(2)
    end

    def analyze_success_rate
      metrics = @telemetry_data[:requests]
      rate = (metrics[:successful].to_f / metrics[:total] * 100).round(2)

      {
        rate: rate,
        successful: metrics[:successful],
        total: metrics[:total],
        grade: grade_success_rate(rate)
      }
    end

    def success_rate_score
      rate = analyze_success_rate[:rate]

      case rate
      when SUCCESS_RATE_THRESHOLDS[:excellent]..100
        100
      when SUCCESS_RATE_THRESHOLDS[:good]...SUCCESS_RATE_THRESHOLDS[:excellent]
        90
      when SUCCESS_RATE_THRESHOLDS[:acceptable]...SUCCESS_RATE_THRESHOLDS[:good]
        75
      else
        [50 * (rate / SUCCESS_RATE_THRESHOLDS[:acceptable]), 0].max.round
      end
    end

    def grade_success_rate(rate)
      if rate >= SUCCESS_RATE_THRESHOLDS[:excellent]
        "excellent"
      elsif rate >= SUCCESS_RATE_THRESHOLDS[:good]
        "good"
      elsif rate >= SUCCESS_RATE_THRESHOLDS[:acceptable]
        "acceptable"
      else
        "poor"
      end
    end

    def analyze_latency
      latencies = @telemetry_data[:latencies]

      {
        p50: latencies[:p50],
        p95: latencies[:p95],
        p99: latencies[:p99],
        samples: latencies[:samples_count],
        grade: grade_latency(latencies)
      }
    end

    def latency_score
      latencies = @telemetry_data[:latencies]

      # Score each percentile and weight them
      scores = [
        { weight: 0.3, score: score_percentile(:p50, latencies[:p50]) },
        { weight: 0.4, score: score_percentile(:p95, latencies[:p95]) },
        { weight: 0.3, score: score_percentile(:p99, latencies[:p99]) }
      ]

      scores.sum { |s| s[:weight] * s[:score] }.round
    end

    def score_percentile(percentile, value)
      thresholds = LATENCY_THRESHOLDS

      if value <= thresholds[:excellent][percentile]
        100
      elsif value <= thresholds[:good][percentile]
        85
      elsif value <= thresholds[:acceptable][percentile]
        70
      else
        # Degrade score proportionally for values above acceptable
        max_value = thresholds[:acceptable][percentile] * 2
        [50 * (1 - (value - thresholds[:acceptable][percentile]) / max_value.to_f), 0].max.round
      end
    end

    def grade_latency(latencies)
      if latencies[:p95] <= LATENCY_THRESHOLDS[:excellent][:p95]
        "excellent"
      elsif latencies[:p95] <= LATENCY_THRESHOLDS[:good][:p95]
        "good"
      elsif latencies[:p95] <= LATENCY_THRESHOLDS[:acceptable][:p95]
        "acceptable"
      else
        "poor"
      end
    end

    def analyze_error_trends
      errors = @telemetry_data[:errors]
      counts = errors.map { |e| e[:count] }

      {
        total_errors: counts.sum,
        average_per_hour: (counts.sum.to_f / counts.size).round(2),
        max_hourly: counts.max,
        min_hourly: counts.min,
        trend: calculate_trend(counts),
        spike_detected: detect_spike(counts)
      }
    end

    def error_trend_score
      trends = analyze_error_trends

      base_score = 100

      # Penalize for high error average
      base_score -= [trends[:average_per_hour] * 2, 30].min

      # Penalize for spikes
      base_score -= 20 if trends[:spike_detected]

      # Bonus for improving trend
      base_score += 10 if trends[:trend] == :decreasing

      # Penalty for worsening trend
      base_score -= 15 if trends[:trend] == :increasing

      [[base_score, 100].min, 0].max.round
    end

    def calculate_trend(counts)
      return :stable if counts.size < 2

      first_half = counts[0...(counts.size / 2)]
      second_half = counts[(counts.size / 2)..]

      first_avg = first_half.sum.to_f / first_half.size
      second_avg = second_half.sum.to_f / second_half.size

      diff = second_avg - first_avg

      if diff > first_avg * 0.1
        :increasing
      elsif diff < -first_avg * 0.1
        :decreasing
      else
        :stable
      end
    end

    def detect_spike(counts)
      return false if counts.size < 3

      avg = counts.sum.to_f / counts.size
      std_dev = Math.sqrt(counts.map { |c| (c - avg)**2 }.sum / counts.size)

      # Spike if any value is more than 2 standard deviations above mean
      counts.any? { |c| c > avg + (2 * std_dev) }
    end

    def analyze_cost_efficiency
      costs = @telemetry_data[:costs]

      {
        total_cost: costs[:total_cost],
        cost_per_request: costs[:cost_per_request],
        cost_trend_percent: (costs[:cost_trend] * 100).round(1),
        efficiency_grade: grade_cost_efficiency(costs)
      }
    end

    def cost_efficiency_score
      costs = @telemetry_data[:costs]

      base_score = 80

      # Reward for low cost per request (under $0.01 is great)
      if costs[:cost_per_request] < 0.01
        base_score += 15
      elsif costs[:cost_per_request] > 0.05
        base_score -= 20
      end

      # Reward/penalize based on cost trend
      if costs[:cost_trend] < -0.1
        base_score += 10 # Costs decreasing significantly
      elsif costs[:cost_trend] > 0.1
        base_score -= 15 # Costs increasing significantly
      end

      [[base_score, 100].min, 0].max
    end

    def grade_cost_efficiency(costs)
      if costs[:cost_per_request] < 0.01 && costs[:cost_trend] <= 0
        "excellent"
      elsif costs[:cost_per_request] < 0.03
        "good"
      elsif costs[:cost_per_request] < 0.05
        "acceptable"
      else
        "poor"
      end
    end
  end
end
