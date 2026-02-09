# frozen_string_literal: true
require "test_helper"

class SecurityScanTest < ActiveSupport::TestCase
  test "factory creates valid security_scan" do
    scan = build(:security_scan)
    assert scan.valid?
  end

  test "with_findings trait includes vulnerabilities" do
    scan = build(:security_scan, :with_findings)

    refute scan.passed
    assert_equal 2, scan.findings.size
  end

  test "failed trait sets passed to false" do
    scan = build(:security_scan, :failed)
    refute scan.passed
  end

  test "severity_counts tracks vulnerability distribution" do
    scan = build(:security_scan, :with_findings)
    counts = scan.severity_counts.deep_symbolize_keys

    assert_equal 1, counts[:critical]
    assert_equal 1, counts[:high]
  end

  test "belongs to agent" do
    agent = create(:agent)
    scan = create(:security_scan, agent: agent)

    assert_equal agent, scan.agent
  end

  test "scanned_at is set" do
    scan = build(:security_scan)
    assert_not_nil scan.scanned_at
  end
end
