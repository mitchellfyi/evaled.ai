# frozen_string_literal: true
namespace :agents do
  desc "Seed agents from GitHub"
  task seed: :environment do
    puts "Starting GitHub agent scrape..."

    search_terms = [
      "ai agent",
      "llm agent",
      "autonomous agent",
      "agentic",
      "mcp server",
      "langchain agent",
      "autogpt",
      "babyagi",
      "crewai",
      "agent framework"
    ]

    search_terms.each do |term|
      puts "Searching: #{term}"
      GithubScraperJob.perform_now(term)
      sleep 2  # Rate limit
    end

    puts "Done! Total agents: #{Agent.count}"
  end

  desc "Show agent stats"
  task stats: :environment do
    puts "Total agents: #{Agent.count}"
    puts "By language:"
    Agent.group(:language).count.sort_by { |_, v| -v }.first(10).each do |lang, count|
      puts "  #{lang || 'Unknown'}: #{count}"
    end
    puts "Top 10 by stars:"
    Agent.order(stars: :desc).limit(10).each do |a|
      puts "  #{a.stars} ⭐ #{a.owner}/#{a.name}"
    end
  end
end
