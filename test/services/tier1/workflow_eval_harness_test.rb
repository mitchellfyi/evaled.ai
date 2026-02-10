# frozen_string_literal: true

require "test_helper"

module Tier1
  class WorkflowEvalHarnessTest < ActiveSupport::TestCase
    setup do
      @agent = create(:agent)
      @task = create(:eval_task, :workflow,
        expected_output: {
          "steps" => [
            { "name" => "Step 1", "action" => "action1" },
            { "name" => "Step 2", "action" => "action2" },
            { "name" => "Step 3", "action" => "action3" }
          ]
        }
      )
    end

    test "run creates EvalRun record" do
      assert_difference -> { EvalRun.count }, 1 do
        WorkflowEvalHarness.new(@agent, @task).run
      end
    end

    test "run returns EvalRun" do
      result = WorkflowEvalHarness.new(@agent, @task).run

      assert_kind_of EvalRun, result
    end

    test "eval_run belongs to agent" do
      result = WorkflowEvalHarness.new(@agent, @task).run

      assert_equal @agent.id, result.agent_id
    end

    test "eval_run belongs to task" do
      result = WorkflowEvalHarness.new(@agent, @task).run

      assert_equal @task.id, result.eval_task_id
    end

    test "completed run has status completed" do
      result = WorkflowEvalHarness.new(@agent, @task).run

      assert_equal "completed", result.status
    end

    test "completed run has completed_at timestamp" do
      result = WorkflowEvalHarness.new(@agent, @task).run

      assert result.completed_at.present?
    end

    test "completed run has started_at timestamp" do
      result = WorkflowEvalHarness.new(@agent, @task).run

      assert result.started_at.present?
    end

    test "completed run has agent_output" do
      result = WorkflowEvalHarness.new(@agent, @task).run

      assert result.agent_output.present?
    end

    test "completed run has metrics" do
      result = WorkflowEvalHarness.new(@agent, @task).run

      assert result.metrics.present?
      assert result.metrics.key?("passed")
      assert result.metrics.key?("completion_rate")
      assert result.metrics.key?("stayed_in_scope")
    end

    test "completed run has duration_ms" do
      result = WorkflowEvalHarness.new(@agent, @task).run

      assert result.duration_ms >= 0
    end

    test "completed run has tokens_used" do
      result = WorkflowEvalHarness.new(@agent, @task).run

      assert result.tokens_used >= 0
    end

    test "executes all steps" do
      harness = WorkflowEvalHarness.new(@agent, @task)

      result = harness.send(:execute_task)

      assert_equal 3, result[:step_results].count
    end

    test "step_results include step number" do
      harness = WorkflowEvalHarness.new(@agent, @task)

      result = harness.send(:execute_task)

      assert_equal 1, result[:step_results].first[:step]
      assert_equal 3, result[:step_results].last[:step]
    end

    test "step_results include step name" do
      harness = WorkflowEvalHarness.new(@agent, @task)

      result = harness.send(:execute_task)

      assert_equal "Step 1", result[:step_results].first[:name]
    end

    test "metrics completion_rate reflects step success" do
      harness = WorkflowEvalHarness.new(@agent, @task)

      # Override to ensure consistent results
      def harness.execute_step(step, index)
        { step: index + 1, name: step["name"], success: index < 2, recovered: false, scope_violation: false, escalated: false, tokens: 100 }
      end

      result = harness.send(:execute_task)
      metrics = harness.send(:calculate_metrics, result)

      assert_in_delta 0.67, metrics[:completion_rate], 0.01
    end

    test "metrics passed is true when all steps succeed" do
      harness = WorkflowEvalHarness.new(@agent, @task)

      def harness.execute_step(step, index)
        { step: index + 1, name: step["name"], success: true, recovered: false, scope_violation: false, escalated: false, tokens: 100 }
      end

      result = harness.send(:execute_task)
      metrics = harness.send(:calculate_metrics, result)

      assert metrics[:passed]
    end

    test "metrics passed is false when any step fails" do
      harness = WorkflowEvalHarness.new(@agent, @task)

      def harness.execute_step(step, index)
        { step: index + 1, name: step["name"], success: index.zero?, recovered: false, scope_violation: false, escalated: false, tokens: 100 }
      end

      result = harness.send(:execute_task)
      metrics = harness.send(:calculate_metrics, result)

      assert_not metrics[:passed]
    end

    test "metrics stayed_in_scope is true with no violations" do
      harness = WorkflowEvalHarness.new(@agent, @task)

      def harness.execute_step(step, index)
        { step: index + 1, name: step["name"], success: true, recovered: false, scope_violation: false, escalated: false, tokens: 100 }
      end

      result = harness.send(:execute_task)
      metrics = harness.send(:calculate_metrics, result)

      assert metrics[:stayed_in_scope]
    end

    test "metrics stayed_in_scope is false with violations" do
      harness = WorkflowEvalHarness.new(@agent, @task)

      def harness.execute_step(step, index)
        { step: index + 1, name: step["name"], success: true, recovered: false, scope_violation: index == 1, escalated: false, tokens: 100 }
      end

      result = harness.send(:execute_task)
      metrics = harness.send(:calculate_metrics, result)

      assert_not metrics[:stayed_in_scope]
      assert_equal 1, metrics[:scope_violations]
    end

    test "metrics error_recovery_rate is 1.0 with no failures" do
      harness = WorkflowEvalHarness.new(@agent, @task)

      def harness.execute_step(step, index)
        { step: index + 1, name: step["name"], success: true, recovered: false, scope_violation: false, escalated: false, tokens: 100 }
      end

      result = harness.send(:execute_task)
      metrics = harness.send(:calculate_metrics, result)

      assert_equal 1.0, metrics[:error_recovery_rate]
    end

    test "handles errors gracefully" do
      harness = WorkflowEvalHarness.new(@agent, @task)

      def harness.execute_task
        raise StandardError, "Workflow failed"
      end

      result = harness.run

      assert_equal "failed", result.status
      assert result.metrics["error"].present?
    end

    test "handles empty steps list" do
      task = create(:eval_task, :workflow, expected_output: { "steps" => [] })
      harness = WorkflowEvalHarness.new(@agent, task)

      result = harness.send(:execute_task)
      metrics = harness.send(:calculate_metrics, result)

      assert_not metrics[:passed]
      assert_equal 0, metrics[:completion_rate]
    end
  end
end
