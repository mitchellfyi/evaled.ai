# frozen_string_literal: true
require "test_helper"

class SecurityAuditTest < ActiveSupport::TestCase
  test "factory creates valid security_audit" do
    audit = build(:security_audit)
    assert audit.valid?
  end

  test "requires auditor" do
    audit = build(:security_audit, auditor: nil)
    refute audit.valid?
    assert_includes audit.errors[:auditor], "can't be blank"
  end

  test "requires audit_type" do
    audit = build(:security_audit, audit_type: nil)
    refute audit.valid?
    assert_includes audit.errors[:audit_type], "can't be blank"
  end

  test "requires audit_date" do
    audit = build(:security_audit, audit_date: nil)
    refute audit.valid?
    assert_includes audit.errors[:audit_date], "can't be blank"
  end

  test "audit_type must be valid" do
    audit = build(:security_audit, audit_type: "invalid")
    refute audit.valid?
    assert_includes audit.errors[:audit_type], "is not included in the list"
  end

  test "accepts valid audit_type values" do
    SecurityAudit::AUDIT_TYPES.each do |type|
      audit = build(:security_audit, audit_type: type)
      assert audit.valid?, "#{type} should be valid"
    end
  end

  test "passed scope returns only passed audits" do
    passed = create(:security_audit, passed: true)
    failed = create(:security_audit, passed: false)

    result = SecurityAudit.passed
    assert_includes result, passed
    refute_includes result, failed
  end

  test "recent scope returns audits from last 90 days" do
    recent = create(:security_audit, audit_date: 30.days.ago)
    old = create(:security_audit, audit_date: 100.days.ago)

    result = SecurityAudit.recent
    assert_includes result, recent
    refute_includes result, old
  end

  test "by_type scope filters by audit_type" do
    automated = create(:security_audit, audit_type: "automated")
    manual = create(:security_audit, audit_type: "manual")

    result = SecurityAudit.by_type("automated")
    assert_includes result, automated
    refute_includes result, manual
  end

  test "critical_findings returns only critical findings" do
    audit = build(:security_audit, findings: [
      { "severity" => "critical", "description" => "RCE" },
      { "severity" => "high", "description" => "SQLi" },
      { "severity" => "critical", "description" => "Auth bypass" }
    ])

    critical = audit.critical_findings
    assert_equal 2, critical.size
    assert critical.all? { |f| f["severity"] == "critical" }
  end

  test "critical_findings returns empty array when no critical findings" do
    audit = build(:security_audit, findings: [
      { "severity" => "high", "description" => "SQLi" }
    ])

    assert_empty audit.critical_findings
  end

  test "critical_findings handles nil findings" do
    audit = build(:security_audit, findings: nil)
    assert_empty audit.critical_findings
  end

  test "high_findings returns only high severity findings" do
    audit = build(:security_audit, findings: [
      { "severity" => "critical", "description" => "RCE" },
      { "severity" => "high", "description" => "SQLi" },
      { "severity" => "medium", "description" => "XSS" }
    ])

    high = audit.high_findings
    assert_equal 1, high.size
    assert_equal "SQLi", high.first["description"]
  end

  test "valid_for_certification? returns true when passed with no critical and recent" do
    audit = create(:security_audit, passed: true, findings: [], audit_date: 10.days.ago)
    assert audit.valid_for_certification?
  end

  test "valid_for_certification? returns false when not passed" do
    audit = create(:security_audit, passed: false, findings: [], audit_date: 10.days.ago)
    refute audit.valid_for_certification?
  end

  test "valid_for_certification? returns false when has critical findings" do
    audit = create(:security_audit, passed: true, findings: [
      { "severity" => "critical", "description" => "RCE" }
    ], audit_date: 10.days.ago)
    refute audit.valid_for_certification?
  end

  test "valid_for_certification? returns false when audit is too old" do
    audit = create(:security_audit, passed: true, findings: [], audit_date: 60.days.ago)
    refute audit.valid_for_certification?
  end

  test "belongs to agent" do
    agent = create(:agent)
    audit = create(:security_audit, agent: agent)

    assert_equal agent, audit.agent
  end
end
