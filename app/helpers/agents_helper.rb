# frozen_string_literal: true
module AgentsHelper
  SCORE_STYLES = {
    (90..100) => { color: "text-green-600", bar: "bg-green-500" },
    (80..89)  => { color: "text-green-500", bar: "bg-green-400" },
    (70..79)  => { color: "text-yellow-600", bar: "bg-yellow-500" },
    (60..69)  => { color: "text-yellow-500", bar: "bg-yellow-400" },
    (50..59)  => { color: "text-orange-500", bar: "bg-orange-500" }
  }.freeze

  CONFIDENCE_STYLES = {
    "high"   => { badge: "bg-green-100 text-green-700", label: "High Confidence" },
    "medium" => { badge: "bg-yellow-100 text-yellow-700", label: "Medium Confidence" },
    "low"    => { badge: "bg-orange-100 text-orange-700", label: "Low Confidence" }
  }.freeze

  CONFIDENCE_TOOLTIPS = {
    "high"   => "Score based on comprehensive Tier 0 and Tier 1 evaluations with multiple recent runs.",
    "medium" => "Score based on Tier 0 evaluation with partial Tier 1 data or recent evaluation activity.",
    "low"    => "Score based on Tier 0 passive signals only. No Tier 1 task evaluations completed."
  }.freeze

  TIER_STYLES = {
    "platinum" => { badge: "bg-gradient-to-r from-slate-300 to-slate-400 text-slate-800", label: "⭐ Platinum" },
    "gold"     => { badge: "bg-gradient-to-r from-yellow-300 to-yellow-400 text-yellow-800", label: "🥇 Gold" },
    "silver"   => { badge: "bg-gradient-to-r from-gray-200 to-gray-300 text-gray-700", label: "🥈 Silver" },
    "bronze"   => { badge: "bg-gradient-to-r from-orange-200 to-orange-300 text-orange-800", label: "🥉 Bronze" }
  }.freeze

  def score_color_class(score)
    return "text-gray-400" unless score
    score_style(score, :color) || "text-red-500"
  end

  def score_bar_class(score)
    return "bg-gray-300" unless score
    score_style(score, :bar) || "bg-red-500"
  end

  def confidence_badge_class(level)
    CONFIDENCE_STYLES.dig(level.to_s, :badge) || "bg-gray-100 text-gray-500"
  end

  def confidence_label(level)
    CONFIDENCE_STYLES.dig(level.to_s, :label) || "Insufficient Data"
  end

  def confidence_tooltip(level)
    CONFIDENCE_TOOLTIPS[level.to_s] ||
      "Minimal data available. This score may change significantly as more evaluations are completed."
  end

  def tier_badge_class(tier)
    TIER_STYLES.dig(tier.to_s, :badge) || "bg-gray-100 text-gray-500"
  end

  def tier_label(tier)
    TIER_STYLES.dig(tier.to_s, :label) || "Unrated"
  end

  def score_trend_indicator(agent)
    scores = agent.evaluations
      .completed
      .where.not(score: nil)
      .order(completed_at: :desc)
      .limit(10)
      .pluck(:score)
      .map(&:to_f)

    return { show: false } if scores.size < 2

    recent = scores.first(3)
    older = scores.last([scores.size / 2, 1].max)

    recent_avg = recent.sum / recent.size
    older_avg = older.sum / older.size
    diff = recent_avg - older_avg

    if diff > 3
      { show: true, icon: "↑", class: "text-green-500", label: "Improving" }
    elsif diff < -3
      { show: true, icon: "↓", class: "text-red-500", label: "Declining" }
    else
      { show: true, icon: "→", class: "text-gray-400", label: "Stable" }
    end
  end

  private

  def score_style(score, key)
    _, style = SCORE_STYLES.find { |range, _| range.cover?(score.to_f) }
    style&.[](key)
  end
end
