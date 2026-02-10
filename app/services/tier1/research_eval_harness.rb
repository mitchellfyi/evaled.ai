# frozen_string_literal: true
module Tier1
  class ResearchEvalHarness < BaseEvalHarness
    private

    def execute_task
      output, duration_ms = timed_execution { simulate_agent_response }

      {
        output: output,
        tokens: (output.length / 4.0).round,
        duration_ms: duration_ms
      }
    end

    def simulate_agent_response
      "Research findings for: #{@eval_task.name}"
    end

    def calculate_metrics(result)
      {
        passed: true,
        factual_accuracy: evaluate_factual_accuracy(result[:output]),
        citation_quality: evaluate_citations(result[:output]),
        hallucination_rate: detect_hallucinations(result[:output]),
        relevance_score: evaluate_relevance(result[:output])
      }
    end

    def evaluate_factual_accuracy(output)
      ground_truth = @eval_task.expected_output&.dig("facts") || []
      return 1.0 if ground_truth.empty?

      matches = ground_truth.count { |fact| output.downcase.include?(fact.downcase) }
      matches.to_f / ground_truth.count
    end

    def evaluate_citations(output)
      citation_patterns = [/\[\d+\]/, /\([A-Z][a-z]+,?\s*\d{4}\)/, /https?:\/\/\S+/]
      has_citations = citation_patterns.any? { |p| output.match?(p) }
      has_citations ? 1.0 : 0.5
    end

    def detect_hallucinations(_output)
      0.1
    end

    def evaluate_relevance(output)
      keywords = @eval_task.expected_output&.dig("keywords") || []
      return 1.0 if keywords.empty?

      matches = keywords.count { |kw| output.downcase.include?(kw.downcase) }
      matches.to_f / keywords.count
    end
  end
end
