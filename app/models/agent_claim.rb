# frozen_string_literal: true
class AgentClaim < ApplicationRecord
  include Expirable

  belongs_to :agent
  belongs_to :user

  VERIFICATION_METHODS = %w[ dns_txt github_file api_key ].freeze
  STATUSES = %w[ pending verified rejected expired ].freeze

  validates :verification_method, presence: true, inclusion: { in: VERIFICATION_METHODS }
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: "pending") }
  scope :verified, -> { where(status: "verified") }
  scope :active, -> { verified.not_expired }

  def verified?
    status == "verified"
  end

  def verify!
    update!(status: "verified", verified_at: Time.current)
  end

  def reject!
    update!(status: "rejected")
  end
end
