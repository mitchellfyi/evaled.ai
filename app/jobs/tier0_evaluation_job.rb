# frozen_string_literal: true
class Tier0EvaluationJob < ApplicationJob
  queue_as :default

  def perform(agent_id)
    agent = Agent.find(agent_id)
    Tier0::ScoringEngine.new(agent).evaluate
  end
end
