class AgentScore < ApplicationRecord
  belongs_to :agent

  validates :tier, presence: true
  validates :overall_score, presence: true, inclusion: { in: 0..100 }

  scope :tier0, -> { where(tier: 0) }
  scope :current, -> { where("expires_at > ?", Time.current) }
  scope :latest, -> { order(evaluated_at: :desc) }
end
