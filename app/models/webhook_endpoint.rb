# frozen_string_literal: true

# Represents a webhook endpoint configured for an agent.
# Webhooks are triggered when scores change.
class WebhookEndpoint < ApplicationRecord
  belongs_to :agent
  has_many :webhook_deliveries, dependent: :destroy

  # Supported webhook event types
  EVENTS = %w[
    score.created
    score.updated
    safety_score.created
    safety_score.updated
  ].freeze

  # Max consecutive failures before auto-disabling
  MAX_FAILURE_COUNT = 5

  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :events, presence: true
  validate :events_are_valid

  scope :active, -> { where(enabled: true) }
  scope :for_event, ->(event) { active.where("? = ANY(events)", event) }

  # Generate a new secret for HMAC signing
  def regenerate_secret!
    update!(secret: SecureRandom.hex(32))
  end

  # Record a successful delivery
  def record_success!
    update!(
      last_triggered_at: Time.current,
      failure_count: 0
    )
  end

  # Record a failed delivery and potentially disable the endpoint
  def record_failure!
    new_count = failure_count + 1
    attrs = { failure_count: new_count }

    if new_count >= MAX_FAILURE_COUNT
      attrs[:enabled] = false
      attrs[:disabled_at] = Time.current
      Rails.logger.warn("[Webhook] Disabling endpoint #{id} after #{new_count} consecutive failures")
    end

    update!(attrs)
  end

  # Re-enable a disabled endpoint
  def reenable!
    update!(
      enabled: true,
      disabled_at: nil,
      failure_count: 0
    )
  end

  private

  def events_are_valid
    return if events.blank?

    invalid = events - EVENTS
    errors.add(:events, "contains invalid events: #{invalid.join(', ')}") if invalid.any?
  end
end
