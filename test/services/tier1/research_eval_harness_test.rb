# frozen_string_literal: true

require "test_helper"

module Tier1
  class ResearchEvalHarnessTest < ActiveSupport::TestCase
    setup do
      @agent = create(:agent)
      @task = create(:eval_task, :research,
        expected_output: {
          "facts" => ["fact1", "fact2"],
          "keywords" => ["keyword1", "keyword2"]
        }
      )
    end

    test "run creates EvalRun record" do
      assert_difference -> { EvalRun.count }, 1 do
        ResearchEvalHarness.new(@agent, @task).run
      end
    end

    test "run returns EvalRun" do
      result = ResearchEvalHarness.new(@agent, @task).run

      assert_kind_of EvalRun, result
    end

    test "eval_run belongs to agent" do
      result = ResearchEvalHarness.new(@agent, @task).run

      assert_equal @agent.id, result.agent_id
    end

    test "eval_run belongs to task" do
      result = ResearchEvalHarness.new(@agent, @task).run

      assert_equal @task.id, result.eval_task_id
    end

    test "completed run has status completed" do
      result = ResearchEvalHarness.new(@agent, @task).run

      assert_equal "completed", result.status
    end

    test "completed run has completed_at timestamp" do
      result = ResearchEvalHarness.new(@agent, @task).run

      assert result.completed_at.present?
    end

    test "completed run has started_at timestamp" do
      result = ResearchEvalHarness.new(@agent, @task).run

      assert result.started_at.present?
    end

    test "completed run has agent_output" do
      result = ResearchEvalHarness.new(@agent, @task).run

      assert result.agent_output.present?
    end

    test "completed run has metrics" do
      result = ResearchEvalHarness.new(@agent, @task).run

      assert result.metrics.present?
      assert result.metrics.key?("passed")
      assert result.metrics.key?("factual_accuracy")
      assert result.metrics.key?("citation_quality")
      assert result.metrics.key?("hallucination_rate")
      assert result.metrics.key?("relevance_score")
    end

    test "completed run has duration_ms" do
      result = ResearchEvalHarness.new(@agent, @task).run

      assert result.duration_ms >= 0
    end

    test "completed run has tokens_used" do
      result = ResearchEvalHarness.new(@agent, @task).run

      assert result.tokens_used >= 0
    end

    test "factual_accuracy is 1.0 when no ground truth" do
      task = create(:eval_task, :research, expected_output: nil)
      harness = ResearchEvalHarness.new(@agent, task)

      accuracy = harness.send(:evaluate_factual_accuracy, "some output")

      assert_equal 1.0, accuracy
    end

    test "factual_accuracy reflects fact matches" do
      harness = ResearchEvalHarness.new(@agent, @task)

      accuracy = harness.send(:evaluate_factual_accuracy, "This contains fact1 but not the other")

      assert_equal 0.5, accuracy
    end

    test "citation_quality is 1.0 with citations" do
      harness = ResearchEvalHarness.new(@agent, @task)

      quality = harness.send(:evaluate_citations, "According to [1] and (Smith, 2024)")

      assert_equal 1.0, quality
    end

    test "citation_quality is 0.5 without citations" do
      harness = ResearchEvalHarness.new(@agent, @task)

      quality = harness.send(:evaluate_citations, "No citations here")

      assert_equal 0.5, quality
    end

    test "citation_quality detects URL citations" do
      harness = ResearchEvalHarness.new(@agent, @task)

      quality = harness.send(:evaluate_citations, "See https://example.com for details")

      assert_equal 1.0, quality
    end

    test "relevance_score is 1.0 when no keywords" do
      task = create(:eval_task, :research, expected_output: nil)
      harness = ResearchEvalHarness.new(@agent, task)

      score = harness.send(:evaluate_relevance, "some output")

      assert_equal 1.0, score
    end

    test "relevance_score reflects keyword matches" do
      harness = ResearchEvalHarness.new(@agent, @task)

      score = harness.send(:evaluate_relevance, "This mentions keyword1")

      assert_equal 0.5, score
    end

    test "handles errors gracefully" do
      harness = ResearchEvalHarness.new(@agent, @task)

      def harness.execute_task
        raise StandardError, "API Error"
      end

      result = harness.run

      assert_equal "failed", result.status
      assert result.metrics["error"].present?
    end

    test "hallucination_rate is a placeholder value" do
      harness = ResearchEvalHarness.new(@agent, @task)

      rate = harness.send(:detect_hallucinations, "any output")

      assert_equal 0.1, rate
    end
  end
end
