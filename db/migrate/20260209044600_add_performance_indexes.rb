class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Agent lookups
    add_index :agents, :stars, order: { stars: :desc }
    add_index :agents, :language
    add_index :agents, [ :featured, :stars ], order: { stars: :desc }

    # API key lookups
    add_index :api_keys, :last_used_at

    # User lookups
    add_index :users, :created_at
  end
end
