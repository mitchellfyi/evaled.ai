# frozen_string_literal: true

module Webhookable
  extend ActiveSupport::Concern

  included do
    after_create :notify_webhook_created
    after_update :notify_webhook_updated, if: :score_changed?
  end

  private

  # Subclasses must implement:
  #   - score_changed? → Boolean
  #   - webhook_payload → Hash
  #   - webhook_event_prefix → String (e.g. "score", "safety_score")

  def notify_webhook_created
    WebhookService.trigger(agent, "#{webhook_event_prefix}.created", webhook_payload)
  rescue StandardError => e
    Rails.logger.error("[Webhook] Failed to trigger #{webhook_event_prefix}.created: #{e.message}")
  end

  def notify_webhook_updated
    WebhookService.trigger(agent, "#{webhook_event_prefix}.updated", webhook_payload)
  rescue StandardError => e
    Rails.logger.error("[Webhook] Failed to trigger #{webhook_event_prefix}.updated: #{e.message}")
  end
end
