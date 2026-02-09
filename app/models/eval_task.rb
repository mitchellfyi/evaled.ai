class EvalTask < ApplicationRecord
  has_many :eval_runs, dependent: :destroy

  CATEGORIES = %w[coding research workflow].freeze
  DIFFICULTIES = %w[easy medium hard].freeze

  validates :name, presence: true
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :difficulty, inclusion: { in: DIFFICULTIES }, allow_nil: true
  validates :prompt, presence: true

  scope :coding, -> { where(category: "coding") }
  scope :research, -> { where(category: "research") }
  scope :workflow, -> { where(category: "workflow") }
end
