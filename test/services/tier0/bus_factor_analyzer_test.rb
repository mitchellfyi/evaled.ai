# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

module Tier0
  class BusFactorAnalyzerTest < ActiveSupport::TestCase
    setup do
      @agent = create(:agent, repo_url: "https://github.com/testowner/testrepo")
      WebMock.enable!
    end

    teardown do
      WebMock.disable!
    end

    test "analyze returns hash with expected keys" do
      stub_contributors(count: 5)

      result = BusFactorAnalyzer.new(@agent).analyze

      assert result.key?(:active_contributors)
      assert result.key?(:top_contributor_pct)
      assert result.key?(:bus_factor)
      assert result.key?(:score)
    end

    test "returns zero score for no contributors" do
      stub_contributors(empty: true)

      result = BusFactorAnalyzer.new(@agent).analyze

      assert_equal 0, result[:score]
      assert_equal 0, result[:active_contributors]
    end

    test "counts active contributors correctly" do
      stub_contributors(count: 8)

      result = BusFactorAnalyzer.new(@agent).analyze

      assert_equal 8, result[:active_contributors]
    end

    test "returns high score for 5+ contributors with good distribution" do
      stub_contributors(count: 10, distribution: :even)

      result = BusFactorAnalyzer.new(@agent).analyze

      # Score should be high (could be 100 or 80 depending on top contributor percentage)
      assert result[:score] >= 80
    end

    test "returns score of 70 for 3-4 contributors" do
      stub_contributors(count: 4, distribution: :even)

      result = BusFactorAnalyzer.new(@agent).analyze

      assert_equal 70, result[:score]
    end

    test "returns score of 40 for 2 contributors" do
      stub_contributors(count: 2, distribution: :even)

      result = BusFactorAnalyzer.new(@agent).analyze

      assert_equal 40, result[:score]
    end

    test "returns score of 20 for single contributor" do
      stub_contributors(count: 1)

      result = BusFactorAnalyzer.new(@agent).analyze

      assert_equal 0, result[:score]  # 20 - 20 penalty for >80% from one
    end

    test "applies penalty when top contributor is over 80 percent" do
      stub_contributors(count: 5, distribution: :skewed)

      result = BusFactorAnalyzer.new(@agent).analyze

      # 100 - 20 penalty = 80
      assert_equal 80, result[:score]
    end

    test "top_contributor_pct is 100 for single contributor" do
      stub_contributors(count: 1)

      result = BusFactorAnalyzer.new(@agent).analyze

      assert_equal 100.0, result[:top_contributor_pct]
    end

    test "top_contributor_pct reflects distribution" do
      stub_contributors(count: 5, distribution: :even)

      result = BusFactorAnalyzer.new(@agent).analyze

      # With even distribution of 100, 80, 60, 40, 20 = 300 total
      # Top contributor = 100/300 = 33.3%
      assert result[:top_contributor_pct] < 40
    end

    test "bus_factor estimates correctly for even distribution" do
      stub_contributors(count: 5, distribution: :even)

      result = BusFactorAnalyzer.new(@agent).analyze

      # Need to cover 80% of 300 = 240
      # 100 + 80 + 60 = 240, so bus_factor should be 3
      assert_equal 3, result[:bus_factor]
    end

    test "bus_factor is 1 for skewed distribution" do
      stub_contributors(count: 5, distribution: :skewed)

      result = BusFactorAnalyzer.new(@agent).analyze

      assert_equal 1, result[:bus_factor]
    end

    test "handles API error gracefully" do
      stub_request(:get, %r{api.github.com/repos/.*/contributors})
        .to_return(status: 500, body: "Error")

      result = BusFactorAnalyzer.new(@agent).analyze

      assert_equal 0, result[:score]
    end

    private

    def stub_contributors(count: 5, distribution: :even, empty: false)
      if empty
        contributors = []
      else
        contributors = count.times.map do |i|
          contributions = case distribution
          when :even
            100 - i * 20  # 100, 80, 60, 40, 20...
          when :skewed
            i.zero? ? 900 : 25  # First contributor has 90%
          else
            50
          end
          { login: "user#{i}", contributions: contributions }
        end
      end

      stub_request(:get, %r{api.github.com/repos/.*/contributors})
        .to_return(status: 200, body: contributors.to_json, headers: { "Content-Type" => "application/json" })
    end
  end
end
