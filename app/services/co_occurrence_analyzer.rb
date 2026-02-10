# frozen_string_literal: true

class CoOccurrenceAnalyzer
  DEFAULT_LIMIT = 5
  LOOKBACK_DAYS = 90

  def self.related_agents(agent, limit: DEFAULT_LIMIT)
    new(agent).related_agents(limit: limit)
  end

  def initialize(agent)
    @agent = agent
  end

  def related_agents(limit: DEFAULT_LIMIT)
    return [] if @agent.nil?

    # Combine multiple signals for co-occurrence
    interaction_partners = interaction_co_occurrences
    category_peers = category_co_occurrences

    # Merge and score
    scored = merge_and_score(interaction_partners, category_peers)

    # Return top N
    scored.first(limit)
  end

  private

  # Agents that have interacted with this agent (via AgentInteraction)
  def interaction_co_occurrences
    # Find agents where this agent was the reporter
    reported_ids = AgentInteraction
                   .where(reporter_agent_id: @agent.id)
                   .where("created_at > ?", LOOKBACK_DAYS.days.ago)
                   .group(:target_agent_id)
                   .count

    # Find agents that reported interactions with this agent
    targeted_ids = AgentInteraction
                   .where(target_agent_id: @agent.id)
                   .where("created_at > ?", LOOKBACK_DAYS.days.ago)
                   .group(:reporter_agent_id)
                   .count

    # Merge counts (bidirectional interactions count more)
    merged = Hash.new(0)
    reported_ids.each { |id, count| merged[id] += count * 2 }  # Outbound interactions weighted higher
    targeted_ids.each { |id, count| merged[id] += count }

    merged
  end

  # Agents in the same category with similar characteristics
  def category_co_occurrences
    return {} if @agent.category.blank?

    peers = Agent.published
                 .where.not(id: @agent.id)
                 .where(category: @agent.category)
                 .where("score IS NOT NULL")

    # Add language bonus
    peers_with_lang_bonus = if @agent.language.present?
                              peers.map do |peer|
                                bonus = peer.language == @agent.language ? 2 : 0
                                [peer.id, 1 + bonus]
                              end.to_h
                            else
                              peers.pluck(:id).index_with { 1 }
                            end

    peers_with_lang_bonus
  end

  def merge_and_score(interaction_data, category_data)
    all_ids = (interaction_data.keys + category_data.keys).uniq

    scored = all_ids.map do |agent_id|
      interaction_score = interaction_data[agent_id].to_i
      category_score = category_data[agent_id].to_i

      # Weight interactions much higher than category similarity
      total_score = (interaction_score * 10) + category_score

      {
        agent_id: agent_id,
        score: total_score,
        from_interactions: interaction_score > 0,
        from_category: category_score > 0
      }
    end

    # Sort by score descending
    sorted = scored.sort_by { |s| -s[:score] }

    # Load agent details
    agent_ids = sorted.map { |s| s[:agent_id] }
    agents = Agent.where(id: agent_ids).published.index_by(&:id)

    sorted.filter_map do |item|
      agent = agents[item[:agent_id]]
      next unless agent

      {
        slug: agent.slug,
        name: agent.name,
        score: agent.decayed_score&.round,
        category: agent.category,
        co_occurrence_score: item[:score],
        from_interactions: item[:from_interactions]
      }
    end
  end
end
