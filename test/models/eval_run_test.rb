# frozen_string_literal: true
require "test_helper"

class EvalRunTest < ActiveSupport::TestCase
  test "factory creates valid eval_run" do
    eval_run = build(:eval_run)
    assert eval_run.valid?
  end

  test "requires status" do
    eval_run = build(:eval_run, status: nil)
    refute eval_run.valid?
    assert_includes eval_run.errors[:status], "can't be blank"
  end

  test "status must be valid" do
    eval_run = build(:eval_run, status: "invalid")
    refute eval_run.valid?
    assert_includes eval_run.errors[:status], "is not included in the list"
  end

  test "accepts valid status values" do
    EvalRun::STATUSES.each do |status|
      eval_run = build(:eval_run, status: status)
      assert eval_run.valid?, "#{status} should be valid"
    end
  end

  test "duration_seconds converts milliseconds to seconds" do
    eval_run = build(:eval_run, duration_ms: 5000)
    assert_equal 5.0, eval_run.duration_seconds
  end

  test "duration_seconds handles nil" do
    eval_run = build(:eval_run, duration_ms: nil)
    assert_equal 0.0, eval_run.duration_seconds
  end

  test "passed? returns true when metrics indicate passed" do
    eval_run = build(:eval_run, metrics: { "passed" => true })
    assert eval_run.passed?
  end

  test "passed? returns false when metrics indicate failed" do
    eval_run = build(:eval_run, metrics: { "passed" => false })
    refute eval_run.passed?
  end

  test "passed? returns false when metrics is nil" do
    eval_run = build(:eval_run, metrics: nil)
    refute eval_run.passed?
  end

  test "passed? returns false when metrics has no passed key" do
    eval_run = build(:eval_run, metrics: { "score" => 85 })
    refute eval_run.passed?
  end

  test "pending scope returns only pending runs" do
    pending = create(:eval_run, status: "pending")
    running = create(:eval_run, :running)
    completed = create(:eval_run, :completed)

    result = EvalRun.pending
    assert_includes result, pending
    refute_includes result, running
    refute_includes result, completed
  end

  test "completed scope returns only completed runs" do
    pending = create(:eval_run, status: "pending")
    completed = create(:eval_run, :completed)

    result = EvalRun.completed
    assert_includes result, completed
    refute_includes result, pending
  end

  test "belongs to agent" do
    agent = create(:agent)
    eval_run = create(:eval_run, agent: agent)

    assert_equal agent, eval_run.agent
  end

  test "belongs to eval_task" do
    task = create(:eval_task)
    eval_run = create(:eval_run, eval_task: task)

    assert_equal task, eval_run.eval_task
  end
end
