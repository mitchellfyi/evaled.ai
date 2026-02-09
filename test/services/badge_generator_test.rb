# frozen_string_literal: true

require "test_helper"

class BadgeGeneratorTest < ActiveSupport::TestCase
  setup do
    @agent = create(:agent, :published, score: 85)
  end

  # generate_svg tests
  test "generate_svg returns SVG for score type" do
    result = BadgeGenerator.generate_svg(@agent, type: "score", style: "flat")

    assert result.include?("<svg")
    assert result.include?("</svg>")
  end

  test "generate_svg returns SVG for tier type" do
    result = BadgeGenerator.generate_svg(@agent, type: "tier", style: "flat")

    assert result.include?("<svg")
  end

  test "generate_svg returns SVG for safety type" do
    result = BadgeGenerator.generate_svg(@agent, type: "safety", style: "flat")

    assert result.include?("<svg")
  end

  test "generate_svg returns SVG for certification type" do
    result = BadgeGenerator.generate_svg(@agent, type: "certification", style: "flat")

    assert result.include?("<svg")
  end

  test "generate_svg defaults to score for unknown type" do
    result = BadgeGenerator.generate_svg(@agent, type: "unknown", style: "flat")

    assert result.include?("<svg")
  end

  test "generate_svg supports plastic style" do
    result = BadgeGenerator.generate_svg(@agent, type: "score", style: "plastic")

    assert result.include?("<svg")
  end

  test "generate_svg supports for-the-badge style" do
    result = BadgeGenerator.generate_svg(@agent, type: "score", style: "for-the-badge")

    assert result.include?("<svg")
  end

  # generate_error_svg tests
  test "generate_error_svg returns SVG with error message" do
    result = BadgeGenerator.generate_error_svg("Error occurred")

    assert result.include?("<svg")
    assert result.include?("Error occurred")
  end

  # COLORS constant tests
  test "COLORS has score colors" do
    assert BadgeGenerator::COLORS.key?(:excellent)
    assert BadgeGenerator::COLORS.key?(:good)
    assert BadgeGenerator::COLORS.key?(:moderate)
    assert BadgeGenerator::COLORS.key?(:poor)
    assert BadgeGenerator::COLORS.key?(:critical)
  end

  test "COLORS has tier colors" do
    assert BadgeGenerator::COLORS.key?(:platinum)
    assert BadgeGenerator::COLORS.key?(:gold)
    assert BadgeGenerator::COLORS.key?(:silver)
    assert BadgeGenerator::COLORS.key?(:bronze)
  end

  test "COLORS has safety colors" do
    assert BadgeGenerator::COLORS.key?(:safe)
    assert BadgeGenerator::COLORS.key?(:caution)
    assert BadgeGenerator::COLORS.key?(:warning)
    assert BadgeGenerator::COLORS.key?(:danger)
  end

  # Score badge color tests
  test "score badge shows excellent color for 80+ score" do
    @agent.update!(score: 90)
    result = BadgeGenerator.generate_svg(@agent, type: "score", style: "flat")

    assert result.include?(BadgeGenerator::COLORS[:excellent])
  end

  test "score badge shows good color for 60-79 score" do
    @agent.update!(score: 70)
    result = BadgeGenerator.generate_svg(@agent, type: "score", style: "flat")

    assert result.include?(BadgeGenerator::COLORS[:good])
  end

  test "score badge shows moderate color for 40-59 score" do
    @agent.update!(score: 50)
    result = BadgeGenerator.generate_svg(@agent, type: "score", style: "flat")

    assert result.include?(BadgeGenerator::COLORS[:moderate])
  end

  test "score badge shows poor color for 20-39 score" do
    @agent.update!(score: 30)
    result = BadgeGenerator.generate_svg(@agent, type: "score", style: "flat")

    assert result.include?(BadgeGenerator::COLORS[:poor])
  end

  test "score badge shows critical color for below 20 score" do
    @agent.update!(score: 10)
    result = BadgeGenerator.generate_svg(@agent, type: "score", style: "flat")

    assert result.include?(BadgeGenerator::COLORS[:critical])
  end
end
