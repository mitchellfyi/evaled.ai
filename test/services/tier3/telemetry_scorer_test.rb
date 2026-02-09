# frozen_string_literal: true

require "test_helper"

module Tier3
  class TelemetryScorerTest < ActiveSupport::TestCase
    setup do
      @agent = create(:agent)
      @scorer = TelemetryScorer.new(@agent)
    end

    test "analyze returns a complete telemetry analysis" do
      result = @scorer.analyze

      assert result.is_a?(Hash)
      assert result.key?(:score)
      assert result.key?(:success_rate)
      assert result.key?(:latency)
      assert result.key?(:error_trends)
      assert result.key?(:cost_efficiency)
      assert result.key?(:analyzed_at)
    end

    test "analyze score is between 0 and 100" do
      result = @scorer.analyze

      assert result[:score] >= 0
      assert result[:score] <= 100
    end

    test "success_rate includes rate and grade" do
      result = @scorer.analyze

      assert result[:success_rate].key?(:rate)
      assert result[:success_rate].key?(:grade)
      assert result[:success_rate].key?(:successful)
      assert result[:success_rate].key?(:total)
    end

    test "latency includes percentiles and grade" do
      result = @scorer.analyze

      assert result[:latency].key?(:p50)
      assert result[:latency].key?(:p95)
      assert result[:latency].key?(:p99)
      assert result[:latency].key?(:grade)
    end

    test "error_trends includes trend analysis" do
      result = @scorer.analyze

      assert result[:error_trends].key?(:total_errors)
      assert result[:error_trends].key?(:average_per_hour)
      assert result[:error_trends].key?(:trend)
      assert result[:error_trends].key?(:spike_detected)
    end

    test "cost_efficiency includes cost metrics" do
      result = @scorer.analyze

      assert result[:cost_efficiency].key?(:total_cost)
      assert result[:cost_efficiency].key?(:cost_per_request)
      assert result[:cost_efficiency].key?(:efficiency_grade)
    end

    test "grades are valid strings" do
      result = @scorer.analyze
      valid_grades = %w[ excellent good acceptable poor ]

      assert_includes valid_grades, result[:success_rate][:grade]
      assert_includes valid_grades, result[:latency][:grade]
      assert_includes valid_grades, result[:cost_efficiency][:efficiency_grade]
    end

    test "trend is a valid symbol" do
      result = @scorer.analyze
      valid_trends = %i[ increasing decreasing stable ]

      assert_includes valid_trends, result[:error_trends][:trend]
    end

    test "spike_detected is boolean" do
      result = @scorer.analyze

      assert [ true, false ].include?(result[:error_trends][:spike_detected])
    end
  end
end
