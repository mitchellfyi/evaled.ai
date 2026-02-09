# frozen_string_literal: true
class CreateSecurityAudits < ActiveRecord::Migration[8.1]
  def change
    create_table :security_audits do |t|
      t.references :agent, null: false, foreign_key: true
      t.string :auditor
      t.string :audit_type
      t.jsonb :findings
      t.jsonb :severity_summary
      t.boolean :passed
      t.date :audit_date
      t.date :expires_at
      t.string :report_url

      t.timestamps
    end
  end
end
