# frozen_string_literal: true

class AddProviderNameIndexToAiModels < ActiveRecord::Migration[8.0]
  def change
    add_index :ai_models, [:provider, :name]
  end
end
