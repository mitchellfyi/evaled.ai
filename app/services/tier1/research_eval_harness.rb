module Tier1
  class ResearchEvalHarness
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

    def execute_task
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      output = simulate_agent_response
      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      {
        output: output,
        tokens: (output.length / 4.0).round,
        duration_ms: ((end_time - start_time) * 1000).round
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
      # Check for citation patterns [1], (Author, Year), URLs
      citation_patterns = [ /\[\d+\]/, /\([A-Z][a-z]+,?\s*\d{4}\)/, /https?:\/\/\S+/ ]
      has_citations = citation_patterns.any? { |p| output.match?(p) }
      has_citations ? 1.0 : 0.5
    end

    def detect_hallucinations(output)
      # Lower is better - placeholder
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
