# frozen_string_literal: true
require "test_helper"

class Api::V1::TelemetryControllerTest < ActionDispatch::IntegrationTest
  setup do
    @agent = create(:agent, :published)
  end

  # ============================================
  # POST /api/v1/telemetry (create)
  # ============================================

  test "create telemetry event with valid params" do
    assert_difference "TelemetryEvent.count", 1 do
      post api_v1_telemetry_index_url, params: {
        telemetry_event: {
          agent_id: @agent.id,
          event_type: "invocation",
          metrics: { latency_ms: 150, tokens: 500 },
          metadata: { source: "sdk", version: "1.0" }
        }
      }, as: :json
    end

    assert_response :created
  end

  test "create telemetry event sets received_at automatically" do
    freeze_time do
      post api_v1_telemetry_index_url, params: {
        telemetry_event: {
          agent_id: @agent.id,
          event_type: "error"
        }
      }, as: :json

      assert_response :created

      event = TelemetryEvent.last
      assert_equal Time.current, event.received_at
    end
  end

  test "create telemetry event with custom received_at" do
    custom_time = 1.hour.ago

    post api_v1_telemetry_index_url, params: {
      telemetry_event: {
        agent_id: @agent.id,
        event_type: "invocation",
        received_at: custom_time.iso8601
      }
    }, as: :json

    assert_response :created

    event = TelemetryEvent.last
    assert_in_delta custom_time.to_i, event.received_at.to_i, 1
  end

  test "create telemetry event fails without event_type" do
    assert_no_difference "TelemetryEvent.count" do
      post api_v1_telemetry_index_url, params: {
        telemetry_event: {
          agent_id: @agent.id
        }
      }, as: :json
    end

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)

    assert_includes json["errors"], "Event type can't be blank"
  end

  test "create telemetry event fails without agent_id" do
    assert_no_difference "TelemetryEvent.count" do
      post api_v1_telemetry_index_url, params: {
        telemetry_event: {
          event_type: "invocation"
        }
      }, as: :json
    end

    assert_response :unprocessable_entity
  end

  test "create telemetry event fails with invalid agent_id" do
    assert_no_difference "TelemetryEvent.count" do
      post api_v1_telemetry_index_url, params: {
        telemetry_event: {
          agent_id: 99999,
          event_type: "invocation"
        }
      }, as: :json
    end

    assert_response :unprocessable_entity
  end

  test "create telemetry event with complex metrics hash" do
    post api_v1_telemetry_index_url, params: {
      telemetry_event: {
        agent_id: @agent.id,
        event_type: "invocation",
        metrics: {
          latency_ms: 250,
          tokens_in: 100,
          tokens_out: 400,
          cost_usd: 0.005
        }
      }
    }, as: :json

    assert_response :created

    event = TelemetryEvent.last
    assert_equal 250, event.metrics["latency_ms"]
    assert_equal 100, event.metrics["tokens_in"]
  end

  test "create telemetry event with complex metadata hash" do
    post api_v1_telemetry_index_url, params: {
      telemetry_event: {
        agent_id: @agent.id,
        event_type: "invocation",
        metadata: {
          source: "production",
          environment: "aws-us-east-1",
          user_id: "user-123",
          session_id: "sess-abc"
        }
      }
    }, as: :json

    assert_response :created

    event = TelemetryEvent.last
    assert_equal "production", event.metadata["source"]
    assert_equal "user-123", event.metadata["user_id"]
  end

  test "create fails without telemetry_event wrapper" do
    post api_v1_telemetry_index_url, params: {
      agent_id: @agent.id,
      event_type: "invocation"
    }, as: :json

    assert_response :bad_request
  end
end
