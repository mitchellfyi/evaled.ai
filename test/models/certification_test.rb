# frozen_string_literal: true
require "test_helper"

class CertificationTest < ActiveSupport::TestCase
  test "factory creates valid certification" do
    cert = build(:certification)
    assert cert.valid?
  end

  test "requires tier" do
    cert = build(:certification, tier: nil)
    refute cert.valid?
    assert_includes cert.errors[:tier], "can't be blank"
  end

  test "requires status" do
    cert = build(:certification, status: nil)
    refute cert.valid?
    assert_includes cert.errors[:status], "can't be blank"
  end

  test "sets applied_at on create if not provided" do
    cert = create(:certification, applied_at: nil)
    assert_not_nil cert.applied_at
  end

  test "does not override provided applied_at" do
    time = 1.week.ago
    cert = create(:certification, applied_at: time)
    assert_equal time.to_i, cert.applied_at.to_i
  end

  test "active scope returns approved certifications with future expiry" do
    active = create(:certification, :active)
    expired = create(:certification, :expired, status: :approved)
    pending = create(:certification, :pending)

    result = Certification.active
    assert_includes result, active
    refute_includes result, expired
    refute_includes result, pending
  end

  test "by_tier scope filters by tier" do
    bronze = create(:certification, :bronze)
    silver = create(:certification, :silver)

    result = Certification.by_tier(:bronze)
    assert_includes result, bronze
    refute_includes result, silver
  end

  test "valid_certification? returns true for approved with future expiry" do
    cert = create(:certification, :approved)
    assert cert.valid_certification?
  end

  test "valid_certification? returns false for pending" do
    cert = build(:certification, :pending)
    refute cert.valid_certification?
  end

  test "valid_certification? returns false for expired" do
    cert = create(:certification, status: :approved, expires_at: 1.day.ago)
    refute cert.valid_certification?
  end

  test "valid_certification? returns false when expires_at is nil" do
    cert = build(:certification, status: :approved, expires_at: nil)
    refute cert.valid_certification?
  end

  test "set_expiry! sets expires_at for bronze tier" do
    cert = create(:certification, tier: :bronze, status: :approved, expires_at: nil)
    cert.set_expiry!

    assert_not_nil cert.expires_at
    assert_in_delta 90.days.from_now.to_i, cert.expires_at.to_i, 5
  end

  test "set_expiry! sets expires_at for silver tier" do
    cert = create(:certification, tier: :silver, status: :approved, expires_at: nil)
    cert.set_expiry!

    assert_in_delta 180.days.from_now.to_i, cert.expires_at.to_i, 5
  end

  test "set_expiry! sets expires_at for gold tier" do
    cert = create(:certification, tier: :gold, status: :approved, expires_at: nil)
    cert.set_expiry!

    assert_in_delta 365.days.from_now.to_i, cert.expires_at.to_i, 5
  end

  test "set_expiry! does nothing if not approved" do
    cert = create(:certification, tier: :bronze, status: :pending, expires_at: nil)
    cert.set_expiry!

    assert_nil cert.expires_at
  end

  test "tier enum works correctly" do
    bronze = build(:certification, tier: :bronze)
    silver = build(:certification, tier: :silver)
    gold = build(:certification, tier: :gold)

    assert bronze.bronze?
    assert silver.silver?
    assert gold.gold?
  end

  test "status enum works correctly" do
    pending = build(:certification, status: :pending)
    in_review = build(:certification, status: :in_review)
    approved = build(:certification, status: :approved)
    rejected = build(:certification, status: :rejected)

    assert pending.pending?
    assert in_review.in_review?
    assert approved.approved?
    assert rejected.rejected?
  end

  test "belongs to agent" do
    agent = create(:agent)
    cert = create(:certification, agent: agent)

    assert_equal agent, cert.agent
  end
end
