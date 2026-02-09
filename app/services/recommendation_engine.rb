# frozen_string_literal: true

class RecommendationEngine
  def self.recommend_for_capability(capability, limit: 5)
    new.recommend_for_capability(capability, limit: limit)
  end

  def self.find_similar_agents(agent)
    new.find_similar_agents(agent)
  end

  def recommend_for_capability(capability, limit: 5)
    return [] if capability.blank?

    Agent.published
         .by_category(capability)
         .order(score: :desc)
         .limit(limit)
         .map { |a| recommendation_data(a, capability) }
  end

  def find_similar_agents(agent, limit: 5)
    return [] if agent.nil?

    # Find agents in the same category with similar scores
    similar = Agent.published
                   .where.not(id: agent.id)
                   .where(category: agent.category)
                   .order(Arel.sql("ABS(score - #{agent.score.to_i})"))
                   .limit(limit)

    similar.map { |a| similarity_data(a, agent) }
  end

  private

  def recommendation_data(agent, capability)
    {
      slug: agent.slug,
      name: agent.name,
      score: agent.score,
      tier: agent.tier,
      match_reason: "Top performer for #{capability}",
      category: agent.category
    }
  end

  def similarity_data(similar_agent, reference_agent)
    {
      slug: similar_agent.slug,
      name: similar_agent.name,
      score: similar_agent.score,
      tier: similar_agent.tier,
      shared_category: similar_agent.category,
      score_difference: (similar_agent.score.to_f - reference_agent.score.to_f).round(1)
    }
  end
end
