# frozen_string_literal: true
class CreateAgentScores < ActiveRecord::Migration[8.1]
  def change
    create_table :agent_scores do |t|
      t.references :agent, null: false, foreign_key: true
      t.integer :tier
      t.integer :overall_score
      t.jsonb :breakdown
      t.datetime :evaluated_at
      t.datetime :expires_at

      t.timestamps
    end
  end
end
