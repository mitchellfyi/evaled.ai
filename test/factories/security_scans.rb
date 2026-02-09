# frozen_string_literal: true

FactoryBot.define do
  factory :security_scan do
    association :agent
    scan_type { "full" }
    findings { [ { type: "info", description: "No issues found" } ] }
    severity_counts { { critical: 0, high: 0, medium: 0, low: 0, unknown: 0 } }
    passed { true }
    scanned_at { Time.current }

    trait :with_findings do
      findings do
        [
          { type: "dependency", package: "rails", severity: "high", summary: "CVE-2024-1234" },
          { type: "code", vulnerability: "SQL Injection", severity: "critical", file: "app.rb" }
        ]
      end
      severity_counts { { critical: 1, high: 1, medium: 0, low: 0, unknown: 0 } }
      passed { false }
    end

    trait :failed do
      passed { false }
      findings { [ { type: "error", severity: "critical", description: "Critical issue" } ] }
      severity_counts { { critical: 1, high: 0, medium: 0, low: 0, unknown: 0 } }
    end
  end
end
