# frozen_string_literal: true

# Periodic job to retry failed webhook deliveries.
# Run this periodically (e.g., every 5 minutes) to catch any deliveries
# that may have been missed by the immediate retry mechanism.
class WebhookRetryJob < ApplicationJob
  queue_as :webhooks

  def perform
    WebhookDelivery.retryable.find_each do |delivery|
      WebhookDeliveryJob.perform_later(delivery.id)
    rescue StandardError => e
      Rails.logger.error("[WebhookRetry] Failed to enqueue delivery #{delivery.id}: #{e.message}")
    end
  end
end
