# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/agent_score_mailer
class AgentScoreMailerPreview < ActionMailer::Preview
  # Preview decay_warning email at http://localhost:3000/rails/mailers/agent_score_mailer/decay_warning
  def decay_warning
    user = User.first || User.new(email: "demo@example.com")
    agent = Agent.first || Agent.new(name: "Demo Agent", slug: "demo-agent")
    agent_score = AgentScore.first || AgentScore.new(
      overall_score: 72.5,
      score_at_eval: 95.0,
      decay_rate: "standard",
      last_verified_at: 60.days.ago
    )

    retention = 76.3
    threshold = 80

    AgentScoreMailer.decay_warning(user, agent, agent_score, retention, threshold)
  end

  # Preview with heavily decayed score
  def decay_warning_critical
    user = User.first || User.new(email: "demo@example.com")
    agent = Agent.first || Agent.new(name: "Critical Agent", slug: "critical-agent")
    agent_score = AgentScore.new(
      overall_score: 45.0,
      score_at_eval: 92.0,
      decay_rate: "fast",
      last_verified_at: 120.days.ago
    )

    retention = 48.9
    threshold = 50

    AgentScoreMailer.decay_warning(user, agent, agent_score, retention, threshold)
  end
end
