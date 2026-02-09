class CreateEvalTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :eval_tasks do |t|
      t.string :name
      t.string :category
      t.string :difficulty
      t.text :description
      t.text :prompt
      t.jsonb :expected_output
      t.jsonb :evaluation_criteria
      t.integer :timeout_seconds
      t.integer :max_tokens

      t.timestamps
    end
  end
end
