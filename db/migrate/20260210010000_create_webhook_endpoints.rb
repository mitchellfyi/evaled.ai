# frozen_string_literal: true

class CreateWebhookEndpoints < ActiveRecord::Migration[8.1]
  def change
    create_table :webhook_endpoints do |t|
      t.references :agent, null: false, foreign_key: true
      t.string :url, null: false
      t.string :secret
      t.string :events, array: true, default: []
      t.boolean :enabled, default: true
      t.datetime :last_triggered_at
      t.integer :failure_count, default: 0
      t.datetime :disabled_at

      t.timestamps
    end

    add_index :webhook_endpoints, [:agent_id, :enabled]
    add_index :webhook_endpoints, :url
  end
end
