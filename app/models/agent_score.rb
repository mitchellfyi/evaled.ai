# frozen_string_literal: true

class AgentScore < ApplicationRecord
  include Webhookable
  include Expirable

  belongs_to :agent

  # Decay rate determines how quickly the score degrades over time
  enum :decay_rate, { slow: "slow", standard: "standard", fast: "fast" }, default: :standard

  validates :tier, presence: true
  validates :overall_score, presence: true, inclusion: { in: 0..100 }

  scope :tier0, -> { where(tier: 0) }
  scope :current, -> { not_expired }
  scope :latest, -> { order(evaluated_at: :desc) }
  scope :needing_reverification, lambda {
    where("next_eval_scheduled_at <= ?", Time.current)
      .or(where(next_eval_scheduled_at: nil))
  }

  # Returns the current decayed score based on time elapsed since evaluation
  #
  # @return [Float] The decayed score value (0-100)
  def decayed_score
    ScoreDecayCalculator.calculate_current_score(self)
  end

  # Returns the percentage of original score retained after decay
  #
  # @return [Float] Retention percentage (0-100)
  def score_retention
    ScoreDecayCalculator.score_retention_percentage(self)
  end

  # Estimates when the score will drop below the given threshold
  #
  # @param threshold [Float] Score threshold (default: 70.0)
  # @return [DateTime, nil] Estimated date
  def estimated_threshold_date(threshold: 70.0)
    ScoreDecayCalculator.estimated_threshold_date(self, threshold: threshold)
  end

  # Records the current score as the baseline for decay calculations
  # Call this when a new evaluation is completed
  def record_evaluation!
    update!(
      score_at_eval: overall_score,
      last_verified_at: Time.current,
      next_eval_scheduled_at: nil
    )
  end

  private

  def score_changed?
    saved_change_to_overall_score? || saved_change_to_score_at_eval?
  end

  def webhook_payload
    {
      agent_id: agent_id,
      agent_slug: agent.slug,
      agent_name: agent.name,
      score_id: id,
      tier: tier,
      overall_score: overall_score,
      decayed_score: decayed_score,
      score_at_eval: score_at_eval,
      decay_rate: decay_rate,
      evaluated_at: evaluated_at&.iso8601,
      expires_at: expires_at&.iso8601,
      breakdown: breakdown
    }
  end

  def webhook_event_prefix
    "score"
  end
end
