class SecurityAudit < ApplicationRecord
  belongs_to :agent

  AUDIT_TYPES = %w[automated manual penetration compliance].freeze
  SEVERITIES = %w[critical high medium low info].freeze

  validates :auditor, presence: true
  validates :audit_type, presence: true, inclusion: { in: AUDIT_TYPES }
  validates :audit_date, presence: true

  scope :passed, -> { where(passed: true) }
  scope :recent, -> { where("audit_date > ?", 90.days.ago) }
  scope :by_type, ->(type) { where(audit_type: type) }

  def critical_findings
    (findings || []).select { |f| f["severity"] == "critical" }
  end

  def high_findings
    (findings || []).select { |f| f["severity"] == "high" }
  end

  def valid_for_certification?
    passed? && critical_findings.empty? && audit_date > 30.days.ago
  end
end
