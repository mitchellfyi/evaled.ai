module Tier0
  class RepoHealthAnalyzer
    def initialize(agent)
      @agent = agent
      @client = GithubClient.new
      parse_repo_url
    end

    def analyze
      {
        commit_recency: analyze_commit_recency,
        commit_frequency: analyze_commit_frequency,
        issue_ratio: analyze_issue_ratio,
        score: calculate_score
      }
    end

    private

    def analyze_commit_recency
      commits = @client.commits(@owner, @repo)
      return 0 if commits.empty? || commits.is_a?(Hash)

      last_commit = Time.parse(commits.first.dig("commit", "committer", "date"))
      days_ago = (Time.current - last_commit) / 1.day

      case days_ago
      when 0..7 then 100
      when 8..30 then 80
      when 31..90 then 50
      else 20
      end
    end

    def analyze_commit_frequency
      commits = @client.commits(@owner, @repo)
      return 0 if commits.empty? || commits.is_a?(Hash)

      # Score based on commits in last 6 months
      commit_count = commits.size

      case commit_count
      when 100.. then 100
      when 50..99 then 80
      when 20..49 then 60
      when 5..19 then 40
      else 20
      end
    end

    def analyze_issue_ratio
      issues = @client.issues(@owner, @repo)
      return 100 if issues.empty? || issues.is_a?(Hash)

      open_issues = issues.count { |i| i["state"] == "open" }
      closed_issues = issues.count { |i| i["state"] == "closed" }
      total = open_issues + closed_issues

      return 100 if total.zero?

      # Higher score for better close ratio
      close_ratio = closed_issues.to_f / total
      (close_ratio * 100).round
    end

    def calculate_score
      recency = analyze_commit_recency
      frequency = analyze_commit_frequency
      issues = analyze_issue_ratio

      # Weighted average: recency 40%, frequency 30%, issues 30%
      ((recency * 0.4) + (frequency * 0.3) + (issues * 0.3)).round
    end

    def parse_repo_url
      match = @agent.repo_url.match(%r{github\.com/([^/]+)/([^/]+)})
      @owner, @repo = match[1], match[2].sub(/\.git$/, "") if match
    end
  end
end
