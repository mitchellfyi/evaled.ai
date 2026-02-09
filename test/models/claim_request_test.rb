require "test_helper"

class ClaimRequestTest < ActiveSupport::TestCase
  test "factory creates valid claim_request" do
    request = build(:claim_request)
    assert request.valid?
  end

  test "verified trait sets status and verification data" do
    request = build(:claim_request, :verified)
    
    assert_equal "verified", request.status.to_s
    assert_not_nil request.verified_at
    assert_not_nil request.github_verification
  end

  test "rejected trait sets status to rejected" do
    request = build(:claim_request, :rejected)
    assert_equal "rejected", request.status.to_s
  end

  test "belongs to agent" do
    agent = create(:agent)
    request = create(:claim_request, agent: agent)

    assert_equal agent, request.agent
  end

  test "belongs to user" do
    user = create(:user)
    request = create(:claim_request, user: user)

    assert_equal user, request.user
  end

  test "requested_at is set" do
    request = build(:claim_request)
    assert_not_nil request.requested_at
  end
end
