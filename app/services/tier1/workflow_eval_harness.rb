# frozen_string_literal: true
module Tier1
  class WorkflowEvalHarness < BaseEvalHarness
    private

    def execute_task
      steps = @eval_task.expected_output&.dig("steps") || []

      step_results, duration_ms = timed_execution do
        steps.map.with_index { |step, i| execute_step(step, i) }
      end

      {
        output: step_results.to_json,
        step_results: step_results,
        tokens: step_results.sum { |s| s[:tokens] || 0 },
        duration_ms: duration_ms
      }
    end

    def execute_step(step, index)
      {
        step: index + 1,
        name: step["name"],
        success: rand > 0.1,
        recovered: false,
        scope_violation: false,
        escalated: false,
        tokens: rand(100..500)
      }
    end

    def calculate_metrics(result)
      steps = result[:step_results] || []
      return { passed: false, completion_rate: 0 } if steps.empty?

      successful = steps.count { |s| s[:success] }
      violations = steps.count { |s| s[:scope_violation] }
      failures = steps.count { |s| !s[:success] }
      recoveries = steps.count { |s| s[:recovered] }

      {
        passed: successful == steps.count,
        completion_rate: successful.to_f / steps.count,
        stayed_in_scope: violations.zero?,
        scope_violations: violations,
        escalated_appropriately: escalation_appropriate?(steps),
        error_recovery_rate: failures > 0 ? recoveries.to_f / failures : 1.0
      }
    end

    def escalation_appropriate?(_steps)
      true
    end
  end
end
