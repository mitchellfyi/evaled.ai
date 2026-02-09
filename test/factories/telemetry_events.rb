# frozen_string_literal: true
FactoryBot.define do
  factory :telemetry_event do
    association :agent
    event_type { "invocation" }
    received_at { Time.current }
    metrics { { latency_ms: 150, tokens: 500 } }
    metadata { { source: "test" } }
  end
end
