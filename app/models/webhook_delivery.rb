# frozen_string_literal: true

# Tracks individual webhook delivery attempts.
# Supports retries with exponential backoff.
class WebhookDelivery < ApplicationRecord
  belongs_to :webhook_endpoint

  STATUSES = %w[pending delivering delivered failed].freeze
  MAX_ATTEMPTS = 5

  # Exponential backoff: 1m, 5m, 15m, 1h, 4h
  RETRY_DELAYS = [1.minute, 5.minutes, 15.minutes, 1.hour, 4.hours].freeze

  validates :event_type, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: "pending") }
  scope :failed, -> { where(status: "failed") }
  scope :retryable, -> { where(status: "pending").where("next_retry_at <= ?", Time.current) }
  scope :recent, -> { order(created_at: :desc) }

  # Mark delivery as in progress
  def mark_delivering!
    update!(status: "delivering", attempt_count: attempt_count + 1)
  end

  # Mark delivery as successful
  def mark_delivered!(response_code:, response_body: nil)
    update!(
      status: "delivered",
      response_code: response_code,
      response_body: response_body&.truncate(1000),
      delivered_at: Time.current,
      error_message: nil
    )
    webhook_endpoint.record_success!
  end

  # Mark delivery as failed with optional retry
  def mark_failed!(error:, response_code: nil, response_body: nil)
    attrs = {
      error_message: error.truncate(500),
      response_code: response_code,
      response_body: response_body&.truncate(1000)
    }

    if attempt_count >= MAX_ATTEMPTS
      attrs[:status] = "failed"
      webhook_endpoint.record_failure!
      Rails.logger.error("[Webhook] Delivery #{id} permanently failed after #{attempt_count} attempts: #{error}")
    else
      attrs[:status] = "pending"
      attrs[:next_retry_at] = Time.current + retry_delay
      Rails.logger.warn("[Webhook] Delivery #{id} failed (attempt #{attempt_count}), retrying at #{attrs[:next_retry_at]}")
    end

    update!(attrs)
  end

  # Can this delivery be retried?
  def retryable?
    status == "pending" && attempt_count < MAX_ATTEMPTS
  end

  private

  def retry_delay
    RETRY_DELAYS[attempt_count - 1] || RETRY_DELAYS.last
  end
end
