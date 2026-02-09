# frozen_string_literal: true

FactoryBot.define do
  factory :security_audit do
    association :agent
    auditor { "SecurityBot" }
    audit_type { "automated" }
    audit_date { Time.current }
    passed { true }
    findings { [] }

    trait :manual do
      audit_type { "manual" }
      auditor { "Security Auditor" }
    end

    trait :penetration do
      audit_type { "penetration" }
      auditor { "PenTest Team" }
    end

    trait :compliance do
      audit_type { "compliance" }
    end

    trait :failed do
      passed { false }
    end

    trait :with_findings do
      findings do
        [
          { severity: "high", description: "SQL injection vulnerability" },
          { severity: "medium", description: "Missing rate limiting" }
        ]
      end
    end

    trait :with_critical_findings do
      passed { false }
      findings do
        [
          { severity: "critical", description: "Remote code execution" },
          { severity: "high", description: "Authentication bypass" }
        ]
      end
    end

    trait :recent do
      audit_date { 10.days.ago }
    end

    trait :old do
      audit_date { 100.days.ago }
    end
  end
end
