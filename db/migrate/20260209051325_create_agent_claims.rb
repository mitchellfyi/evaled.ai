class CreateAgentClaims < ActiveRecord::Migration[8.1]
  def change
    create_table :agent_claims do |t|
      t.references :agent, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :verification_method
      t.jsonb :verification_data
      t.string :status
      t.datetime :verified_at
      t.datetime :expires_at

      t.timestamps
    end
  end
end
