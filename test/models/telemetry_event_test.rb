require "test_helper"

class TelemetryEventTest < ActiveSupport::TestCase
  test "factory creates valid telemetry_event" do
    event = build(:telemetry_event)
    assert event.valid?
  end

  test "belongs to agent" do
    agent = create(:agent)
    event = create(:telemetry_event, agent: agent)

    assert_equal agent, event.agent
  end

  test "event_type is set" do
    event = build(:telemetry_event)
    assert_equal "invocation", event.event_type
  end

  test "metrics contains expected data" do
    event = build(:telemetry_event)
    metrics = event.metrics.deep_symbolize_keys

    assert metrics.key?(:latency_ms)
    assert metrics.key?(:tokens)
  end

  test "metadata can store additional info" do
    event = build(:telemetry_event, metadata: { source: "api", user_id: 123 })

    assert_equal "api", event.metadata["source"]
    assert_equal 123, event.metadata["user_id"]
  end

  test "received_at is set" do
    event = build(:telemetry_event)
    assert_not_nil event.received_at
  end
end
