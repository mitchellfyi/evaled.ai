# frozen_string_literal: true

FactoryBot.define do
  factory :evaluation do
    association :agent
    tier { "tier0" }
    status { "pending" }
    scores { { coding: 80, research: 75 } }
    score { 77.5 }

    trait :running do
      status { "running" }
      started_at { Time.current }
    end

    trait :completed do
      status { "completed" }
      started_at { 1.hour.ago }
      completed_at { Time.current }
    end

    trait :failed do
      status { "failed" }
      started_at { 1.hour.ago }
      completed_at { Time.current }
      notes { "Evaluation failed: timeout" }
    end

    trait :tier1 do
      tier { "tier1" }
    end

    trait :tier2 do
      tier { "tier2" }
    end
  end
end
