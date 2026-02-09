# frozen_string_literal: true

require "test_helper"

module Tier3
  class AnomalyDetectorTest < ActiveSupport::TestCase
    setup do
      @agent = create(:agent)
      @detector = AnomalyDetector.new(@agent)
    end

    test "detect returns complete anomaly analysis" do
      result = @detector.detect

      assert result.is_a?(Hash)
      assert result.key?(:anomalies)
      assert result.key?(:anomaly_count)
      assert result.key?(:critical_count)
      assert result.key?(:warning_count)
      assert result.key?(:analyzed_at)
      assert result.key?(:health_status)
    end

    test "anomalies is an array" do
      result = @detector.detect

      assert result[:anomalies].is_a?(Array)
    end

    test "anomaly_count matches anomalies array length" do
      result = @detector.detect

      assert_equal result[:anomalies].size, result[:anomaly_count]
    end

    test "critical_count is accurate" do
      result = @detector.detect
      actual_criticals = result[:anomalies].count { |a| a[:severity] == "critical" }

      assert_equal actual_criticals, result[:critical_count]
    end

    test "warning_count is accurate" do
      result = @detector.detect
      actual_warnings = result[:anomalies].count { |a| a[:severity] == "warning" }

      assert_equal actual_warnings, result[:warning_count]
    end

    test "each anomaly has required fields" do
      result = @detector.detect

      result[:anomalies].each do |anomaly|
        assert anomaly.key?(:type), "Anomaly missing type"
        assert anomaly.key?(:severity), "Anomaly missing severity"
        assert anomaly.key?(:timestamp), "Anomaly missing timestamp"
        assert anomaly.key?(:details), "Anomaly missing details"
        assert anomaly.key?(:message), "Anomaly missing message"
      end
    end

    test "anomaly types are valid" do
      result = @detector.detect
      valid_types = %w[ performance_drop error_spike unusual_usage ]

      result[:anomalies].each do |anomaly|
        assert_includes valid_types, anomaly[:type]
      end
    end

    test "severity levels are valid" do
      result = @detector.detect
      valid_severities = %w[ info warning critical ]

      result[:anomalies].each do |anomaly|
        assert_includes valid_severities, anomaly[:severity]
      end
    end

    test "health_status is valid" do
      result = @detector.detect
      valid_statuses = %w[ healthy stable at_risk degraded ]

      assert_includes valid_statuses, result[:health_status]
    end

    test "detects performance drops" do
      result = @detector.detect
      performance_drops = result[:anomalies].select { |a| a[:type] == "performance_drop" }

      # The sample data includes a significant latency spike at hour 13
      assert performance_drops.any?, "Should detect performance drops in sample data"
    end

    test "detects error spikes" do
      result = @detector.detect
      error_spikes = result[:anomalies].select { |a| a[:type] == "error_spike" }

      # The sample data includes an error spike at hour 12
      assert error_spikes.any?, "Should detect error spikes in sample data"
    end

    test "anomaly details contain relevant information" do
      result = @detector.detect
      performance_drops = result[:anomalies].select { |a| a[:type] == "performance_drop" }

      if performance_drops.any?
        drop = performance_drops.first
        assert drop[:details].key?(:hour)
        assert drop[:details].key?(:p95_before)
        assert drop[:details].key?(:p95_after)
      end
    end

    test "error spike details include multiplier" do
      result = @detector.detect
      error_spikes = result[:anomalies].select { |a| a[:type] == "error_spike" }

      if error_spikes.any?
        spike = error_spikes.first
        assert spike[:details].key?(:error_count)
        assert spike[:details].key?(:baseline)
        assert spike[:details].key?(:multiplier)
      end
    end
  end
end
