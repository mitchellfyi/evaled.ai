require "test_helper"

class AgentClaimTest < ActiveSupport::TestCase
  test "factory creates valid agent_claim" do
    claim = build(:agent_claim)
    assert claim.valid?
  end

  test "verified trait sets status and verified_at" do
    claim = build(:agent_claim, :verified)

    assert_equal "verified", claim.status
    assert_not_nil claim.verified_at
  end

  test "rejected trait sets status to rejected" do
    claim = build(:agent_claim, :rejected)
    assert_equal "rejected", claim.status
  end

  test "expired trait has past expires_at" do
    claim = build(:agent_claim, :expired)
    assert claim.expires_at < Time.current
  end

  test "dns_verification trait uses dns_txt method" do
    claim = build(:agent_claim, :dns_verification)
    assert_equal "dns_txt", claim.verification_method
  end

  test "api_key_verification trait uses api_key method" do
    claim = build(:agent_claim, :api_key_verification)
    assert_equal "api_key", claim.verification_method
  end

  test "belongs to agent" do
    agent = create(:agent)
    claim = create(:agent_claim, agent: agent)

    assert_equal agent, claim.agent
  end

  test "belongs to user" do
    user = create(:user)
    claim = create(:agent_claim, user: user)

    assert_equal user, claim.user
  end

  test "verification_data contains token" do
    claim = build(:agent_claim)
    assert claim.verification_data.key?(:token) || claim.verification_data.key?("token")
  end
end
