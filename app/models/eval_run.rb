class EvalRun < ApplicationRecord
  belongs_to :agent
  belongs_to :eval_task

  STATUSES = %w[ pending running completed failed ].freeze

  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: "pending") }
  scope :completed, -> { where(status: "completed") }

  def duration_seconds
    duration_ms.to_f / 1000
  end

  def passed?
    metrics&.dig("passed") == true
  end
end
