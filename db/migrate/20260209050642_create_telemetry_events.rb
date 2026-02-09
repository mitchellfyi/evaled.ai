# frozen_string_literal: true
class CreateTelemetryEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :telemetry_events do |t|
      t.references :agent, null: false, foreign_key: true
      t.string :event_type
      t.jsonb :metrics
      t.jsonb :metadata
      t.datetime :received_at

      t.timestamps
    end
  end
end
