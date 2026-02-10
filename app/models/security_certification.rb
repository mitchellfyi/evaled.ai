# frozen_string_literal: true
class SecurityCertification < ApplicationRecord
  include Expirable

  belongs_to :agent

  CERTIFICATION_TYPES = %w[ safety security compliance enterprise ].freeze
  LEVELS = %w[ bronze silver gold platinum ].freeze

  validates :certification_type, presence: true, inclusion: { in: CERTIFICATION_TYPES }
  validates :level, presence: true, inclusion: { in: LEVELS }
  validates :issued_at, presence: true

  scope :active, -> { not_expired }
  scope :by_type, ->(type) { where(certification_type: type) }

  def active?
    !expired?
  end

  def level_rank
    LEVELS.index(level) || 0
  end
end
