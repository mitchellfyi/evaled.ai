# frozen_string_literal: true

FactoryBot.define do
  factory :eval_run do
    association :agent
    association :eval_task
    status { "pending" }

    trait :running do
      status { "running" }
      started_at { Time.current }
    end

    trait :completed do
      status { "completed" }
      started_at { 1.minute.ago }
      completed_at { Time.current }
      agent_output { "Test output" }
      metrics { { passed: true, score: 85 } }
      duration_ms { 1500 }
      tokens_used { 500 }
    end

    trait :failed do
      status { "failed" }
      started_at { 1.minute.ago }
      completed_at { Time.current }
      metrics { { error: "Test error" } }
    end
  end
end
