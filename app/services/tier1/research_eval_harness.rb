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

        # Execute the research task
        result = execute_task

        # Calculate research-specific metrics
        metrics = calculate_metrics(result)

        eval_run.update!(
          status: "completed",
          agent_output: result[:output],
          metrics: metrics,
          tokens_used: result[:tokens],
          duration_ms: result[:duration_ms],
          completed_at: Time.current
        )
      rescue StandardError => e
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

      # Execute agent with research prompt
      output = execute_agent_with_prompt

      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      {
        output: output,
        tokens: estimate_tokens(output),
        duration_ms: ((end_time - start_time) * 1000).round
      }
    end

    def execute_agent_with_prompt
      # Placeholder for actual agent execution
      # In production, this would call the agent's API with the research prompt
      "# Simulated research response for: #{@eval_task.name}"
    end

    def estimate_tokens(text)
      (text.length / 4.0).round
    end

    def calculate_metrics(result)
      output = result[:output]
      sources = extract_sources(output)
      ground_truth = @eval_task.expected_output
      expected_topics = @eval_task.metadata&.dig("expected_topics") || []

      hallucination_rate = detect_hallucinations(output, sources)
      factual_accuracy = verify_facts(output, ground_truth)
      citation_accuracy = verify_citations(output)
      relevance_score = calculate_relevance(output, expected_topics)

      {
        completed: output.present?,
        factual_accuracy: factual_accuracy,
        citation_accuracy: citation_accuracy,
        hallucination_rate: hallucination_rate,
        relevance_score: relevance_score
      }
    end

    def detect_hallucinations(output, sources)
      return 0.0 if output.blank? || sources.empty?

      # Extract claims from output
      claims = extract_claims(output)
      return 0.0 if claims.empty?

      # Count claims not supported by sources
      unsupported_count = claims.count do |claim|
        !claim_supported_by_sources?(claim, sources)
      end

      (unsupported_count.to_f / claims.length).round(3)
    end

    def verify_facts(output, ground_truth)
      return 1.0 if ground_truth.blank?

      # Extract key facts from ground truth
      expected_facts = extract_key_facts(ground_truth)
      return 1.0 if expected_facts.empty?

      # Check how many expected facts are present in output
      matched_facts = expected_facts.count do |fact|
        output.downcase.include?(fact.downcase)
      end

      (matched_facts.to_f / expected_facts.length).round(3)
    end

    def verify_citations(output)
      # Extract citations from output (e.g., [1], [Source: ...], URLs)
      citations = extract_citations(output)
      return 0.0 if citations.empty?

      # Verify citation format and presence
      valid_citations = citations.count { |citation| valid_citation?(citation) }

      (valid_citations.to_f / citations.length).round(3)
    end

    def calculate_relevance(output, expected_topics)
      return 1.0 if expected_topics.empty?

      # Check topic coverage in output
      covered_topics = expected_topics.count do |topic|
        output.downcase.include?(topic.downcase)
      end

      (covered_topics.to_f / expected_topics.length).round(3)
    end

    # Helper methods

    def extract_sources(output)
      # Extract URLs and references from output
      urls = output.scan(%r{https?://[^\s\])"']+})
      references = output.scan(/\[([^\]]+)\]/).flatten
      (urls + references).uniq
    end

    def extract_claims(output)
      # Split into sentences and filter for factual claims
      sentences = output.split(/[.!?]+/).map(&:strip).reject(&:blank?)
      sentences.select { |s| appears_to_be_claim?(s) }
    end

    def appears_to_be_claim?(sentence)
      # Heuristic: claims typically contain verbs and are declarative
      sentence.length > 20 &&
        !sentence.start_with?("?") &&
        !sentence.match?(/^(Note|Warning|Disclaimer)/i)
    end

    def claim_supported_by_sources?(claim, sources)
      # Placeholder: in production, would cross-reference with source content
      # For now, check if claim references any source
      sources.any? { |source| claim.include?(source) || source.include?(claim[0..20]) }
    end

    def extract_key_facts(ground_truth)
      # Extract distinct facts from ground truth
      ground_truth.split(/[.!?]+/).map(&:strip).reject(&:blank?).first(10)
    end

    def extract_citations(output)
      # Match various citation formats
      bracketed = output.scan(/\[(\d+)\]/).flatten
      named = output.scan(/\[Source:\s*([^\]]+)\]/).flatten
      urls = output.scan(%r{https?://[^\s\])"']+})
      (bracketed + named + urls).uniq
    end

    def valid_citation?(citation)
      # Check if citation is properly formatted
      citation.present? &&
        (citation.match?(/^\d+$/) || # Numbered citation
         citation.match?(%r{^https?://}) || # URL
         citation.length > 3) # Named source
    end
  end
end
