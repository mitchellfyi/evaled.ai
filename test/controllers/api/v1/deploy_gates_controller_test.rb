# frozen_string_literal: true
require "test_helper"

class Api::V1::DeployGatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @high_score_agent = create(:agent, :published, :with_score, slug: "high-score", score: 85.0, score_at_eval: 85.0)
    @medium_score_agent = create(:agent, :published, :with_score, slug: "medium-score", score: 72.0, score_at_eval: 72.0)
    @low_score_agent = create(:agent, :published, :with_score, slug: "low-score", score: 55.0, score_at_eval: 55.0)
    @unpublished_agent = create(:agent, slug: "unpublished", score: 90.0)
  end

  # ============================================
  # POST /api/v1/deploy_gates/check
  # ============================================

  test "check passes when all agents meet threshold" do
    post check_api_v1_deploy_gates_url, params: {
      agents: ["high-score", "medium-score"],
      min_score: 70
    }, as: :json

    assert_response :success
    json = JSON.parse(response.body)

    assert json["pass"], "Deploy gate should pass"
    assert_equal 70, json["threshold"]
    assert_equal 2, json["agents"].size
    assert_equal "2/2 agents passed (min_score: 70)", json["summary"]
  end

  test "check fails when some agents below threshold" do
    post check_api_v1_deploy_gates_url, params: {
      agents: ["high-score", "low-score"],
      min_score: 70
    }, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)

    assert_not json["pass"], "Deploy gate should fail"
    assert_equal "1/2 agents passed (min_score: 70)", json["summary"]

    low_result = json["agents"].find { |a| a["agent"] == "low-score" }
    assert_not low_result["pass"]
  end

  test "check uses default min_score of 70" do
    post check_api_v1_deploy_gates_url, params: {
      agents: ["medium-score"]
    }, as: :json

    assert_response :success
    json = JSON.parse(response.body)

    assert_equal 70, json["threshold"]
    assert json["pass"]
  end

  test "check with custom min_score" do
    post check_api_v1_deploy_gates_url, params: {
      agents: ["medium-score"],
      min_score: 80
    }, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)

    assert_not json["pass"]
    assert_equal 80, json["threshold"]
  end

  test "check returns 400 when agents parameter missing" do
    post check_api_v1_deploy_gates_url, params: {
      min_score: 70
    }, as: :json

    assert_response :bad_request
    json = JSON.parse(response.body)

    assert_equal "agents parameter is required", json["error"]
  end

  test "check returns 400 when agents array is empty" do
    post check_api_v1_deploy_gates_url, params: {
      agents: []
    }, as: :json

    assert_response :bad_request
  end

  test "check includes agent not found error for unknown slugs" do
    post check_api_v1_deploy_gates_url, params: {
      agents: ["high-score", "nonexistent-agent"]
    }, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)

    assert_not json["pass"]

    missing = json["agents"].find { |a| a["agent"] == "nonexistent-agent" }
    assert missing
    assert_not missing["pass"]
    assert_equal "Agent not found", missing["error"]
    assert_nil missing["score"]
  end

  test "check treats unpublished agents as not found" do
    post check_api_v1_deploy_gates_url, params: {
      agents: ["unpublished"]
    }, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)

    result = json["agents"].first
    assert_not result["pass"]
    assert_equal "Agent not found", result["error"]
  end

  test "check returns checked_at timestamp" do
    freeze_time do
      post check_api_v1_deploy_gates_url, params: {
        agents: ["high-score"]
      }, as: :json

      json = JSON.parse(response.body)
      assert_equal Time.current.iso8601, json["checked_at"]
    end
  end

  test "check returns last_verified for each agent" do
    post check_api_v1_deploy_gates_url, params: {
      agents: ["high-score"]
    }, as: :json

    json = JSON.parse(response.body)
    agent_result = json["agents"].first

    assert agent_result.key?("last_verified")
    assert agent_result["last_verified"].present?
  end

  test "check returns agent name for found agents" do
    post check_api_v1_deploy_gates_url, params: {
      agents: ["high-score"]
    }, as: :json

    json = JSON.parse(response.body)
    agent_result = json["agents"].first

    assert agent_result.key?("name")
    assert_equal @high_score_agent.name, agent_result["name"]
  end

  test "check handles single agent as string" do
    # Some clients might send agents as a string instead of array
    post check_api_v1_deploy_gates_url, params: {
      agents: "high-score"
    }, as: :json

    assert_response :success
    json = JSON.parse(response.body)

    assert json["pass"]
    assert_equal 1, json["agents"].size
  end

  test "check with all agents failing" do
    post check_api_v1_deploy_gates_url, params: {
      agents: ["low-score", "nonexistent"],
      min_score: 70
    }, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)

    assert_not json["pass"]
    assert_equal "0/2 agents passed (min_score: 70)", json["summary"]
  end

  test "check handles minimum score of 0" do
    post check_api_v1_deploy_gates_url, params: {
      agents: ["low-score"],
      min_score: 0
    }, as: :json

    assert_response :success
    json = JSON.parse(response.body)

    assert json["pass"]
  end

  test "check handles maximum score of 100" do
    post check_api_v1_deploy_gates_url, params: {
      agents: ["high-score"],
      min_score: 100
    }, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)

    assert_not json["pass"]
  end
end
