# frozen_string_literal: true

module Tier1
  class BaseEvalHarness
    def initialize(agent, eval_task)
      @agent = agent
      @eval_task = eval_task
    end

    def run
      eval_run = create_eval_run

      begin
        eval_run.update!(status: "running", started_at: Time.current)

        result = execute_task
        metrics = calculate_metrics(result)

        eval_run.update!(
          status: "completed",
          agent_output: result[:output],
          metrics: metrics,
          tokens_used: result[:tokens],
          duration_ms: result[:duration_ms],
          completed_at: Time.current
        )
      rescue => e
        eval_run.update!(
          status: "failed",
          metrics: { error: e.message },
          completed_at: Time.current
        )
      end

      eval_run
    end

    private

    def create_eval_run
      EvalRun.create!(
        agent: @agent,
        eval_task: @eval_task,
        status: "pending"
      )
    end

    # Subclasses must implement:
    #   - execute_task → Hash with :output, :tokens, :duration_ms
    #   - calculate_metrics(result) → Hash

    def execute_task
      raise NotImplementedError
    end

    def calculate_metrics(_result)
      raise NotImplementedError
    end

    def timed_execution
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result = yield
      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      duration_ms = ((end_time - start_time) * 1000).round
      [result, duration_ms]
    end
  end
end
