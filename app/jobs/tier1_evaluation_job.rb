# frozen_string_literal: true
class Tier1EvaluationJob < ApplicationJob
  queue_as :default

  def perform(agent_id)
    agent = Agent.find(agent_id)

    # Run coding eval if agent has code capabilities
    EvalTask.coding.find_each do |task|
      Tier1::CodingEvalHarness.new(agent, task).run
    end

    # Run research eval
    EvalTask.research.find_each do |task|
      Tier1::ResearchEvalHarness.new(agent, task).run
    end

    # Run workflow eval
    EvalTask.workflow.find_each do |task|
      Tier1::WorkflowEvalHarness.new(agent, task).run
    end
  end
end
