class CreateSecurityCertifications < ActiveRecord::Migration[8.1]
  def change
    create_table :security_certifications do |t|
      t.references :agent, null: false, foreign_key: true
      t.string :certification_type
      t.string :level
      t.datetime :issued_at
      t.datetime :expires_at
      t.string :issuer
      t.string :badge_url

      t.timestamps
    end
  end
end
