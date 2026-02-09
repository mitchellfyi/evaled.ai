# frozen_string_literal: true
require "test_helper"

class EvalTaskTest < ActiveSupport::TestCase
  test "factory creates valid eval_task" do
    task = build(:eval_task)
    assert task.valid?
  end

  test "requires name" do
    task = build(:eval_task, name: nil)
    refute task.valid?
    assert_includes task.errors[:name], "can't be blank"
  end

  test "requires category" do
    task = build(:eval_task, category: nil)
    refute task.valid?
    assert_includes task.errors[:category], "can't be blank"
  end

  test "requires prompt" do
    task = build(:eval_task, prompt: nil)
    refute task.valid?
    assert_includes task.errors[:prompt], "can't be blank"
  end

  test "category must be valid" do
    task = build(:eval_task, category: "invalid")
    refute task.valid?
    assert_includes task.errors[:category], "is not included in the list"
  end

  test "accepts valid category values" do
    EvalTask::CATEGORIES.each do |category|
      task = build(:eval_task, category: category)
      assert task.valid?, "#{category} should be valid"
    end
  end

  test "difficulty must be valid when present" do
    task = build(:eval_task, difficulty: "invalid")
    refute task.valid?
    assert_includes task.errors[:difficulty], "is not included in the list"
  end

  test "difficulty can be nil" do
    task = build(:eval_task, difficulty: nil)
    assert task.valid?
  end

  test "accepts valid difficulty values" do
    EvalTask::DIFFICULTIES.each do |difficulty|
      task = build(:eval_task, difficulty: difficulty)
      assert task.valid?, "#{difficulty} should be valid"
    end
  end

  test "coding scope returns only coding tasks" do
    coding = create(:eval_task, category: "coding")
    research = create(:eval_task, category: "research")

    result = EvalTask.coding
    assert_includes result, coding
    refute_includes result, research
  end

  test "research scope returns only research tasks" do
    coding = create(:eval_task, category: "coding")
    research = create(:eval_task, category: "research")

    result = EvalTask.research
    assert_includes result, research
    refute_includes result, coding
  end

  test "workflow scope returns only workflow tasks" do
    workflow = create(:eval_task, category: "workflow")
    coding = create(:eval_task, category: "coding")

    result = EvalTask.workflow
    assert_includes result, workflow
    refute_includes result, coding
  end

  test "has many eval_runs" do
    task = create(:eval_task)
    run1 = create(:eval_run, eval_task: task)
    run2 = create(:eval_run, eval_task: task)

    assert_includes task.eval_runs, run1
    assert_includes task.eval_runs, run2
  end

  test "destroying task destroys associated eval_runs" do
    task = create(:eval_task)
    run = create(:eval_run, eval_task: task)
    run_id = run.id

    task.destroy

    refute EvalRun.exists?(run_id)
  end
end
