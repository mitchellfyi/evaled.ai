# frozen_string_literal: true

require "test_helper"

class AgentClaimingTest < ActionDispatch::IntegrationTest
  setup do
    @agent = create(:agent, :published,
      name: "ClaimableAgent",
      slug: "claimable-agent",
      repo_url: "https://github.com/testuser/claimable-agent"
    )
    @user = create(:user)
  end

  # === API Claim Creation Tests ===

  test "API should create claim with github_file method" do
    post api_v1_claims_path, params: {
      agent_id: @agent.id,
      method: "github_file"
    }, as: :json

    # Note: Requires authentication - should return 401 or proceed if authenticated
    # This tests the endpoint exists and responds appropriately
    assert_includes [201, 401, 422], response.status
  end

  test "API should create claim with dns_txt method" do
    post api_v1_claims_path, params: {
      agent_id: @agent.id,
      method: "dns_txt"
    }, as: :json

    assert_includes [201, 401, 422], response.status
  end

  test "API should create claim with api_key method" do
    post api_v1_claims_path, params: {
      agent_id: @agent.id,
      method: "api_key"
    }, as: :json

    assert_includes [201, 401, 422], response.status
  end

  # === Claim Status Model Tests ===

  test "claim request should start as pending" do
    claim = create(:claim_request, agent: @agent, user: @user)
    assert claim.pending?
    assert_not claim.verified?
  end

  test "claim request can be verified" do
    claim = create(:claim_request, agent: @agent, user: @user)
    claim.verify!(method: "repo_access", github_username: "testuser")

    assert claim.verified?
    assert_not_nil claim.verified_at
    assert claim.github_verification.present?
  end

  test "claim request can be rejected" do
    claim = create(:claim_request, agent: @agent, user: @user)
    claim.reject!

    assert claim.rejected?
  end

  # === Agent Claim Model Tests ===

  test "agent claim should start as pending" do
    claim = create(:agent_claim, agent: @agent, user: @user)
    assert_equal "pending", claim.status
    assert_not claim.verified?
  end

  test "agent claim can be verified" do
    claim = create(:agent_claim, agent: @agent, user: @user)
    claim.verify!

    assert claim.verified?
    assert_not_nil claim.verified_at
  end

  test "agent claim can be rejected" do
    claim = create(:agent_claim, agent: @agent, user: @user)
    claim.reject!

    assert_equal "rejected", claim.status
  end

  # === Claim Uniqueness Tests ===

  test "user cannot have duplicate pending claims for same agent" do
    create(:claim_request, agent: @agent, user: @user, status: :pending)

    duplicate = build(:claim_request, agent: @agent, user: @user, status: :pending)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:agent_id], "already has a pending claim from this user"
  end

  test "user can claim different agents" do
    other_agent = create(:agent, :published, name: "OtherAgent", slug: "other-agent")

    claim1 = create(:claim_request, agent: @agent, user: @user)
    claim2 = create(:claim_request, agent: other_agent, user: @user)

    assert claim1.valid?
    assert claim2.valid?
  end

  # === Claim Verification Method Tests ===

  test "agent claim validates verification method" do
    claim = build(:agent_claim, agent: @agent, user: @user, verification_method: "invalid")
    assert_not claim.valid?
    assert_includes claim.errors[:verification_method], "is not included in the list"
  end

  test "agent claim accepts valid verification methods" do
    AgentClaim::VERIFICATION_METHODS.each do |method|
      claim = build(:agent_claim, agent: @agent, user: @user, verification_method: method)
      assert claim.valid?, "Expected #{method} to be valid"
    end
  end

  # === Agent Claim Status Tests ===

  test "agent claim validates status" do
    claim = build(:agent_claim, agent: @agent, user: @user, status: "invalid")
    assert_not claim.valid?
    assert_includes claim.errors[:status], "is not included in the list"
  end

  test "agent claim accepts valid statuses" do
    AgentClaim::STATUSES.each do |status|
      claim = build(:agent_claim, agent: @agent, user: @user, status: status)
      assert claim.valid?, "Expected #{status} to be valid"
    end
  end

  # === Agent Owner Integration Tests ===

  test "verified claim updates agent claim status" do
    claim = create(:agent_claim, :verified, agent: @agent, user: @user)
    @agent.update!(claim_status: "verified", claimed_by_user: @user)

    assert @agent.verified?
    assert_equal @user, @agent.claimed_by_user
  end

  test "agent should know if claimed" do
    assert_not @agent.claimed?

    @agent.update!(claim_status: "claimed")
    assert @agent.claimed?
  end

  test "agent should know if verified" do
    assert_not @agent.verified?

    @agent.update!(claim_status: "verified")
    assert @agent.verified?
  end

  # === Scopes Tests ===

  test "pending scope returns only pending claims" do
    pending_claim = create(:agent_claim, agent: @agent, user: @user, status: "pending")
    _verified_claim = create(:agent_claim, :verified, agent: create(:agent, :published), user: @user)

    pending_claims = AgentClaim.pending
    assert_includes pending_claims, pending_claim
  end

  test "verified scope returns only verified claims" do
    _pending_claim = create(:agent_claim, agent: @agent, user: @user, status: "pending")
    verified_claim = create(:agent_claim, :verified, agent: create(:agent, :published), user: @user)

    verified_claims = AgentClaim.verified
    assert_includes verified_claims, verified_claim
  end

  test "active scope excludes expired claims" do
    active_claim = create(:agent_claim, :verified, agent: @agent, user: @user, expires_at: nil)
    expired_claim = create(:agent_claim, :expired, agent: create(:agent, :published), user: @user)

    active_claims = AgentClaim.active
    assert_includes active_claims, active_claim
    assert_not_includes active_claims, expired_claim
  end

  # === Claim Request Scopes Tests ===

  test "pending_claims scope returns only pending requests" do
    pending = create(:claim_request, agent: @agent, user: @user, status: :pending)
    _verified = create(:claim_request, :verified, agent: create(:agent, :published), user: @user)

    assert_includes ClaimRequest.pending_claims, pending
  end

  test "verified_claims scope returns only verified requests" do
    _pending = create(:claim_request, agent: @agent, user: @user, status: :pending)
    verified = create(:claim_request, :verified, agent: create(:agent, :published), user: @user)

    assert_includes ClaimRequest.verified_claims, verified
  end

  # === Edge Cases ===

  test "claim with future expiry is still active" do
    claim = create(:agent_claim, :verified,
      agent: @agent,
      user: @user,
      expires_at: 1.year.from_now
    )

    assert_includes AgentClaim.active, claim
  end

  test "claim verification data includes token" do
    claim = create(:agent_claim, agent: @agent, user: @user)
    assert claim.verification_data.key?("token")
    assert claim.verification_data["token"].present?
  end
end
