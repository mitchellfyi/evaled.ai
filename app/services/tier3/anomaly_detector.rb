# frozen_string_literal: true

module Tier3
  class AnomalyDetector
    # Detect unusual patterns in telemetry data
    #
    # Detects:
    # - Sudden performance drops
    # - Error rate spikes
    # - Unusual usage patterns

    SEVERITY_LEVELS = %w[ info warning critical ].freeze

    # Thresholds for anomaly detection
    PERFORMANCE_DROP_THRESHOLD = 0.20    # 20% drop is significant
    ERROR_SPIKE_MULTIPLIER = 3.0         # 3x normal error rate is a spike
    USAGE_DEVIATION_THRESHOLD = 2.5      # Standard deviations for unusual usage

    def initialize(agent)
      @agent = agent
      @anomalies = []
    end

    def detect
      historical_data = fetch_historical_data

      detect_performance_drops(historical_data)
      detect_error_spikes(historical_data)
      detect_unusual_usage(historical_data)

      {
        anomalies: @anomalies,
        anomaly_count: @anomalies.size,
        critical_count: @anomalies.count { |a| a[:severity] == "critical" },
        warning_count: @anomalies.count { |a| a[:severity] == "warning" },
        analyzed_at: Time.current.iso8601,
        health_status: determine_health_status
      }
    end

    private

    def fetch_historical_data
      # Placeholder: would fetch from actual telemetry store
      {
        latency_history: generate_latency_history,
        error_history: generate_error_history,
        usage_history: generate_usage_history
      }
    end

    def generate_latency_history
      # Simulated 24-hour latency data (hourly averages in ms)
      [
        { hour: 0, p50: 110, p95: 420 },
        { hour: 1, p50: 105, p95: 400 },
        { hour: 2, p50: 100, p95: 380 },
        { hour: 3, p50: 95, p95: 360 },
        { hour: 4, p50: 90, p95: 350 },
        { hour: 5, p50: 95, p95: 360 },
        { hour: 6, p50: 110, p95: 420 },
        { hour: 7, p50: 130, p95: 480 },
        { hour: 8, p50: 150, p95: 520 },
        { hour: 9, p50: 160, p95: 550 },
        { hour: 10, p50: 165, p95: 560 },
        { hour: 11, p50: 170, p95: 580 },
        { hour: 12, p50: 180, p95: 600 },  # Performance drop
        { hour: 13, p50: 250, p95: 900 },  # Significant drop
        { hour: 14, p50: 160, p95: 550 },
        { hour: 15, p50: 155, p95: 530 },
        { hour: 16, p50: 150, p95: 520 },
        { hour: 17, p50: 145, p95: 510 },
        { hour: 18, p50: 140, p95: 500 },
        { hour: 19, p50: 130, p95: 470 },
        { hour: 20, p50: 125, p95: 450 },
        { hour: 21, p50: 120, p95: 440 },
        { hour: 22, p50: 115, p95: 430 },
        { hour: 23, p50: 110, p95: 420 }
      ]
    end

    def generate_error_history
      # Simulated 24-hour error counts
      [
        { hour: 0, count: 12 },
        { hour: 1, count: 8 },
        { hour: 2, count: 5 },
        { hour: 3, count: 4 },
        { hour: 4, count: 3 },
        { hour: 5, count: 5 },
        { hour: 6, count: 10 },
        { hour: 7, count: 15 },
        { hour: 8, count: 18 },
        { hour: 9, count: 20 },
        { hour: 10, count: 22 },
        { hour: 11, count: 25 },
        { hour: 12, count: 80 },  # Error spike!
        { hour: 13, count: 45 },
        { hour: 14, count: 20 },
        { hour: 15, count: 18 },
        { hour: 16, count: 17 },
        { hour: 17, count: 16 },
        { hour: 18, count: 15 },
        { hour: 19, count: 14 },
        { hour: 20, count: 13 },
        { hour: 21, count: 12 },
        { hour: 22, count: 11 },
        { hour: 23, count: 10 }
      ]
    end

    def generate_usage_history
      # Simulated 24-hour request counts
      [
        { hour: 0, requests: 500 },
        { hour: 1, requests: 350 },
        { hour: 2, requests: 200 },
        { hour: 3, requests: 150 },
        { hour: 4, requests: 120 },
        { hour: 5, requests: 180 },
        { hour: 6, requests: 400 },
        { hour: 7, requests: 800 },
        { hour: 8, requests: 1200 },
        { hour: 9, requests: 1500 },
        { hour: 10, requests: 1600 },
        { hour: 11, requests: 1700 },
        { hour: 12, requests: 1800 },
        { hour: 13, requests: 1750 },
        { hour: 14, requests: 1650 },
        { hour: 15, requests: 1600 },
        { hour: 16, requests: 1550 },
        { hour: 17, requests: 1450 },
        { hour: 18, requests: 1300 },
        { hour: 19, requests: 1100 },
        { hour: 20, requests: 900 },
        { hour: 21, requests: 750 },
        { hour: 22, requests: 600 },
        { hour: 23, requests: 550 }
      ]
    end

    def detect_performance_drops(data)
      latencies = data[:latency_history]

      latencies.each_cons(2) do |prev, curr|
        p50_change = (curr[:p50] - prev[:p50]).to_f / prev[:p50]
        p95_change = (curr[:p95] - prev[:p95]).to_f / prev[:p95]

        if p95_change > PERFORMANCE_DROP_THRESHOLD
          severity = p95_change > 0.5 ? "critical" : "warning"

          @anomalies << {
            type: "performance_drop",
            severity: severity,
            timestamp: hours_ago(24 - curr[:hour]),
            details: {
              hour: curr[:hour],
              p50_before: prev[:p50],
              p50_after: curr[:p50],
              p95_before: prev[:p95],
              p95_after: curr[:p95],
              p95_change_percent: (p95_change * 100).round(1)
            },
            message: "P95 latency increased by #{(p95_change * 100).round(1)}% " \
                     "(#{prev[:p95]}ms → #{curr[:p95]}ms)"
          }
        end
      end
    end

    def detect_error_spikes(data)
      errors = data[:error_history]
      counts = errors.map { |e| e[:count] }

      # Calculate baseline (median of non-spike values)
      sorted_counts = counts.sort
      baseline = sorted_counts[sorted_counts.size / 2]

      errors.each do |entry|
        if entry[:count] > baseline * ERROR_SPIKE_MULTIPLIER
          multiplier = entry[:count].to_f / baseline
          severity = multiplier > 5 ? "critical" : "warning"

          @anomalies << {
            type: "error_spike",
            severity: severity,
            timestamp: hours_ago(24 - entry[:hour]),
            details: {
              hour: entry[:hour],
              error_count: entry[:count],
              baseline: baseline,
              multiplier: multiplier.round(1)
            },
            message: "Error count spiked to #{entry[:count]} " \
                     "(#{multiplier.round(1)}x normal baseline of #{baseline})"
          }
        end
      end
    end

    def detect_unusual_usage(data)
      usage = data[:usage_history]
      requests = usage.map { |u| u[:requests] }

      mean = requests.sum.to_f / requests.size
      std_dev = Math.sqrt(requests.map { |r| (r - mean)**2 }.sum / requests.size)

      usage.each do |entry|
        z_score = (entry[:requests] - mean) / std_dev

        if z_score.abs > USAGE_DEVIATION_THRESHOLD
          direction = z_score.positive? ? "high" : "low"
          severity = z_score.abs > 3.5 ? "warning" : "info"

          @anomalies << {
            type: "unusual_usage",
            severity: severity,
            timestamp: hours_ago(24 - entry[:hour]),
            details: {
              hour: entry[:hour],
              requests: entry[:requests],
              mean: mean.round,
              z_score: z_score.round(2),
              direction: direction
            },
            message: "Unusually #{direction} usage: #{entry[:requests]} requests " \
                     "(#{z_score.abs.round(1)} standard deviations from mean of #{mean.round})"
          }
        end
      end
    end

    def hours_ago(hours)
      (Time.current - hours.hours).iso8601
    end

    def determine_health_status
      critical = @anomalies.count { |a| a[:severity] == "critical" }
      warnings = @anomalies.count { |a| a[:severity] == "warning" }

      if critical.positive?
        "degraded"
      elsif warnings > 2
        "at_risk"
      elsif warnings.positive?
        "stable"
      else
        "healthy"
      end
    end
  end
end
