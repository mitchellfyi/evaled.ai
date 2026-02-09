require "test_helper"

class EvaluationTest < ActiveSupport::TestCase
  test "factory creates valid evaluation" do
    evaluation = build(:evaluation)
    assert evaluation.valid?
  end

  test "requires tier" do
    evaluation = build(:evaluation, tier: nil)
    refute evaluation.valid?
    assert_includes evaluation.errors[:tier], "can't be blank"
  end

  test "tier must be valid" do
    evaluation = build(:evaluation, tier: "invalid")
    refute evaluation.valid?
    assert_includes evaluation.errors[:tier], "is not included in the list"
  end

  test "accepts valid tier values" do
    %w[tier0 tier1 tier2].each do |tier|
      evaluation = build(:evaluation, tier: tier)
      assert evaluation.valid?, "#{tier} should be valid"
    end
  end

  test "status must be valid" do
    evaluation = build(:evaluation, status: "invalid")
    refute evaluation.valid?
    assert_includes evaluation.errors[:status], "is not included in the list"
  end

  test "accepts valid status values" do
    %w[pending running completed failed].each do |status|
      evaluation = build(:evaluation, status: status)
      assert evaluation.valid?, "#{status} should be valid"
    end
  end

  test "duration returns nil when not completed" do
    evaluation = build(:evaluation, started_at: nil, completed_at: nil)
    assert_nil evaluation.duration
  end

  test "duration calculates difference between started_at and completed_at" do
    started = 1.hour.ago
    completed = Time.current
    evaluation = build(:evaluation, started_at: started, completed_at: completed)

    assert_in_delta 3600, evaluation.duration, 1
  end

  test "mark_running! updates status and started_at" do
    evaluation = create(:evaluation)
    evaluation.mark_running!

    assert_equal "running", evaluation.status
    assert_not_nil evaluation.started_at
  end

  test "mark_completed! updates status, scores, and completed_at" do
    evaluation = create(:evaluation, :running)
    new_scores = { coding: 90, research: 85 }

    evaluation.mark_completed!(new_scores)

    assert_equal "completed", evaluation.status
    assert_equal new_scores, evaluation.scores.deep_symbolize_keys
    assert_equal 87.5, evaluation.score
    assert_not_nil evaluation.completed_at
  end

  test "mark_failed! updates status and completed_at" do
    evaluation = create(:evaluation, :running)
    evaluation.mark_failed!("Error occurred")

    assert_equal "failed", evaluation.status
    assert_equal "Error occurred", evaluation.notes
    assert_not_nil evaluation.completed_at
  end

  test "completed scope returns only completed evaluations" do
    completed = create(:evaluation, :completed)
    pending = create(:evaluation, status: "pending")
    running = create(:evaluation, :running)

    result = Evaluation.completed
    assert_includes result, completed
    refute_includes result, pending
    refute_includes result, running
  end

  test "by_tier scope filters by tier" do
    tier0 = create(:evaluation, tier: "tier0")
    tier1 = create(:evaluation, tier: "tier1")

    result = Evaluation.by_tier("tier0")
    assert_includes result, tier0
    refute_includes result, tier1
  end

  test "recent scope orders by created_at descending" do
    old = create(:evaluation, created_at: 2.days.ago)
    recent = create(:evaluation, created_at: 1.day.ago)
    newest = create(:evaluation, created_at: Time.current)

    result = Evaluation.recent.to_a
    assert_equal [newest, recent, old], result
  end

  test "compute_overall_score returns nil for blank scores" do
    evaluation = create(:evaluation)
    evaluation.mark_completed!({})

    assert_nil evaluation.score
  end

  test "compute_overall_score averages all score values" do
    evaluation = create(:evaluation)
    evaluation.mark_completed!({ a: 100, b: 80, c: 60 })

    assert_equal 80.0, evaluation.score
  end
end
