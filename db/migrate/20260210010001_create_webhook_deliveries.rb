# frozen_string_literal: true

class CreateWebhookDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :webhook_deliveries do |t|
      t.references :webhook_endpoint, null: false, foreign_key: true
      t.string :event_type, null: false
      t.jsonb :payload, default: {}
      t.string :status, default: "pending"
      t.integer :attempt_count, default: 0
      t.integer :response_code
      t.text :response_body
      t.text :error_message
      t.datetime :delivered_at
      t.datetime :next_retry_at

      t.timestamps
    end

    add_index :webhook_deliveries, :status
    add_index :webhook_deliveries, :next_retry_at
    add_index :webhook_deliveries, [:webhook_endpoint_id, :created_at]
  end
end
