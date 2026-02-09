# frozen_string_literal: true
class CreateEvalRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :eval_runs do |t|
      t.references :agent, null: false, foreign_key: true
      t.references :eval_task, null: false, foreign_key: true
      t.string :status
      t.text :agent_output
      t.jsonb :metrics
      t.integer :tokens_used
      t.integer :duration_ms
      t.decimal :cost_usd
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end
  end
end
