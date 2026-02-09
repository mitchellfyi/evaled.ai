class SecurityCertification < ApplicationRecord
  belongs_to :agent
  
  CERTIFICATION_TYPES = %w[safety security compliance enterprise].freeze
  LEVELS = %w[bronze silver gold platinum].freeze
  
  validates :certification_type, presence: true, inclusion: { in: CERTIFICATION_TYPES }
  validates :level, presence: true, inclusion: { in: LEVELS }
  validates :issued_at, presence: true
  
  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :by_type, ->(type) { where(certification_type: type) }
  
  def active?
    expires_at.nil? || expires_at > Time.current
  end
  
  def level_rank
    LEVELS.index(level) || 0
  end
end
