# frozen_string_literal: true

FactoryBot.define do
  factory :safety_score do
    association :agent
    overall_score { 85.0 }
    badge { "🟢" }
    breakdown do
      {
        prompt_injection: { score: 90, tests_passed: 9, tests_total: 10 },
        jailbreak: { score: 85, tests_passed: 17, tests_total: 20 },
        boundary: { score: 80, tests_passed: 8, tests_total: 10 },
        consistency: { score: 85, tests_passed: 0, tests_total: 0 }
      }
    end

    trait :unsafe do
      overall_score { 45.0 }
      badge { "🔴" }
    end

    trait :caution do
      overall_score { 75.0 }
      badge { "🟡" }
    end
  end
end
