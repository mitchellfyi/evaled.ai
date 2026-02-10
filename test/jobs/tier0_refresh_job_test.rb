# frozen_string_literal: true

require "test_helper"

class Tier0RefreshJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "job is enqueued to low queue" do
    assert_equal "low", Tier0RefreshJob.new.queue_name
  end

  test "queues Tier0EvaluationJob for agents needing refresh" do
    agent = create(:agent, repo_url: "https://github.com/test/repo")

    assert_enqueued_with(job: Tier0EvaluationJob, args: [agent.id]) do
      Tier0RefreshJob.perform_now
    end
  end

  test "skips agents without repo_url" do
    create(:agent, repo_url: nil)
    create(:agent, repo_url: "")

    assert_no_enqueued_jobs(only: Tier0EvaluationJob) do
      Tier0RefreshJob.perform_now
    end
  end

  test "skips agents evaluated recently" do
    agent = create(:agent, repo_url: "https://github.com/test/repo")

    # Create a recent score
    create(:agent_score,
      agent: agent,
      tier: 0,
      overall_score: 75,
      evaluated_at: 1.hour.ago,
      expires_at: 30.days.from_now
    )

    assert_no_enqueued_jobs(only: Tier0EvaluationJob) do
      Tier0RefreshJob.perform_now
    end
  end

  test "processes agents with stale evaluations" do
    agent = create(:agent, repo_url: "https://github.com/test/repo")

    # Create a stale score (older than 23 hours)
    create(:agent_score,
      agent: agent,
      tier: 0,
      overall_score: 75,
      evaluated_at: 25.hours.ago,
      expires_at: 30.days.from_now
    )

    assert_enqueued_with(job: Tier0EvaluationJob, args: [agent.id]) do
      Tier0RefreshJob.perform_now
    end
  end

  test "queues next batch when more agents remain" do
    # Create multiple agents beyond batch size
    (Tier0RefreshJob::BATCH_SIZE + 5).times do |i|
      create(:agent, repo_url: "https://github.com/test/repo-#{i}", stars: 100 - i)
    end

    assert_enqueued_with(job: Tier0RefreshJob) do
      Tier0RefreshJob.perform_now
    end
  end

  test "prioritizes agents by stars" do
    low_stars = create(:agent, repo_url: "https://github.com/test/low", stars: 10)
    high_stars = create(:agent, repo_url: "https://github.com/test/high", stars: 1000)

    jobs = []
    assert_enqueued_jobs(2, only: Tier0EvaluationJob) do
      Tier0RefreshJob.perform_now
    end

    # High stars agent should be processed first (order by stars desc)
    enqueued = enqueued_jobs.select { |j| j["job_class"] == "Tier0EvaluationJob" }
    assert_equal high_stars.id, enqueued.first["arguments"].first
  end
end
