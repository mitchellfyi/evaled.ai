# frozen_string_literal: true

# Background job for delivering webhooks with retry support.
# Uses exponential backoff for failed deliveries.
class WebhookDeliveryJob < ApplicationJob
  queue_as :webhooks

  # Retry configuration - let the WebhookDelivery model handle retry logic
  discard_on ActiveRecord::RecordNotFound

  def perform(delivery_id)
    delivery = WebhookDelivery.find(delivery_id)

    # Skip if already delivered or permanently failed
    return if delivery.status == "delivered"
    return if delivery.status == "failed"

    # Skip if not yet time to retry
    if delivery.next_retry_at.present? && delivery.next_retry_at > Time.current
      # Re-enqueue for later
      self.class.set(wait_until: delivery.next_retry_at).perform_later(delivery_id)
      return
    end

    endpoint = delivery.webhook_endpoint

    # Skip if endpoint is disabled
    unless endpoint.enabled?
      Rails.logger.info("[Webhook] Skipping delivery #{delivery_id} - endpoint disabled")
      return
    end

    WebhookService.new(endpoint).deliver(delivery)

    # If delivery failed but is retryable, schedule the next attempt
    if delivery.reload.retryable? && delivery.next_retry_at.present?
      self.class.set(wait_until: delivery.next_retry_at).perform_later(delivery_id)
    end
  end
end
