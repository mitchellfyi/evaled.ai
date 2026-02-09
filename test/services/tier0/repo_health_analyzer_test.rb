# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

module Tier0
  class RepoHealthAnalyzerTest < ActiveSupport::TestCase
    setup do
      @agent = create(:agent, repo_url: "https://github.com/testowner/testrepo")
      WebMock.enable!
    end

    teardown do
      WebMock.disable!
    end

    test "analyze returns hash with expected keys" do
      stub_github_commits(recent: true, count: 50)
      stub_github_issues(open: 5, closed: 15)

      result = RepoHealthAnalyzer.new(@agent).analyze

      assert result.key?(:commit_recency)
      assert result.key?(:commit_frequency)
      assert result.key?(:issue_ratio)
      assert result.key?(:score)
    end

    test "commit_recency returns 100 for commits within 7 days" do
      stub_github_commits(recent: true, count: 10)
      stub_github_issues

      result = RepoHealthAnalyzer.new(@agent).analyze

      assert_equal 100, result[:commit_recency]
    end

    test "commit_recency returns 80 for commits 8-30 days ago" do
      stub_github_commits(days_ago: 15, count: 10)
      stub_github_issues

      result = RepoHealthAnalyzer.new(@agent).analyze

      assert_equal 80, result[:commit_recency]
    end

    test "commit_recency returns 50 for commits 31-90 days ago" do
      stub_github_commits(days_ago: 60, count: 10)
      stub_github_issues

      result = RepoHealthAnalyzer.new(@agent).analyze

      assert_equal 50, result[:commit_recency]
    end

    test "commit_recency returns 20 for old commits" do
      stub_github_commits(days_ago: 180, count: 10)
      stub_github_issues

      result = RepoHealthAnalyzer.new(@agent).analyze

      assert_equal 20, result[:commit_recency]
    end

    test "commit_recency returns 0 for no commits" do
      stub_github_commits(empty: true)
      stub_github_issues

      result = RepoHealthAnalyzer.new(@agent).analyze

      assert_equal 0, result[:commit_recency]
    end

    test "commit_frequency returns 100 for 100+ commits" do
      stub_github_commits(count: 150)
      stub_github_issues

      result = RepoHealthAnalyzer.new(@agent).analyze

      assert_equal 100, result[:commit_frequency]
    end

    test "commit_frequency returns 80 for 50-99 commits" do
      stub_github_commits(count: 75)
      stub_github_issues

      result = RepoHealthAnalyzer.new(@agent).analyze

      assert_equal 80, result[:commit_frequency]
    end

    test "commit_frequency returns 60 for 20-49 commits" do
      stub_github_commits(count: 35)
      stub_github_issues

      result = RepoHealthAnalyzer.new(@agent).analyze

      assert_equal 60, result[:commit_frequency]
    end

    test "commit_frequency returns 40 for 5-19 commits" do
      stub_github_commits(count: 10)
      stub_github_issues

      result = RepoHealthAnalyzer.new(@agent).analyze

      assert_equal 40, result[:commit_frequency]
    end

    test "commit_frequency returns 20 for less than 5 commits" do
      stub_github_commits(count: 3)
      stub_github_issues

      result = RepoHealthAnalyzer.new(@agent).analyze

      assert_equal 20, result[:commit_frequency]
    end

    test "issue_ratio returns 100 for no issues" do
      stub_github_commits
      stub_github_issues(empty: true)

      result = RepoHealthAnalyzer.new(@agent).analyze

      assert_equal 100, result[:issue_ratio]
    end

    test "issue_ratio reflects close ratio" do
      stub_github_commits
      stub_github_issues(open: 2, closed: 8)

      result = RepoHealthAnalyzer.new(@agent).analyze

      assert_equal 80, result[:issue_ratio]
    end

    test "issue_ratio handles all open issues" do
      stub_github_commits
      stub_github_issues(open: 10, closed: 0)

      result = RepoHealthAnalyzer.new(@agent).analyze

      assert_equal 0, result[:issue_ratio]
    end

    test "score is weighted average of all metrics" do
      stub_github_commits(recent: true, count: 100)  # recency: 100, frequency: 100
      stub_github_issues(open: 0, closed: 10)  # ratio: 100

      result = RepoHealthAnalyzer.new(@agent).analyze

      # All 100s should give score of 100
      assert_equal 100, result[:score]
    end

    test "handles error response from GitHub commits" do
      stub_request(:get, %r{api.github.com/repos/.*/commits})
        .to_return(status: 200, body: { message: "Not Found" }.to_json)
      stub_github_issues

      result = RepoHealthAnalyzer.new(@agent).analyze

      assert_equal 0, result[:commit_recency]
    end

    test "handles error response from GitHub issues" do
      stub_github_commits
      stub_request(:get, %r{api.github.com/repos/.*/issues})
        .to_return(status: 200, body: { message: "Not Found" }.to_json)

      result = RepoHealthAnalyzer.new(@agent).analyze

      assert_equal 100, result[:issue_ratio]
    end

    private

    def stub_github_commits(recent: true, count: 10, days_ago: 1, empty: false)
      if empty
        commits = []
      else
        commit_date = (Time.current - days_ago.days).iso8601
        commits = count.times.map do |i|
          {
            sha: SecureRandom.hex(20),
            commit: {
              committer: { date: commit_date },
              message: "Commit #{i}"
            }
          }
        end
      end

      stub_request(:get, %r{api.github.com/repos/.*/commits})
        .to_return(status: 200, body: commits.to_json, headers: { "Content-Type" => "application/json" })
    end

    def stub_github_issues(open: 5, closed: 5, empty: false)
      if empty
        issues = []
      else
        issues = []
        open.times { issues << { state: "open" } }
        closed.times { issues << { state: "closed" } }
      end

      stub_request(:get, %r{api.github.com/repos/.*/issues})
        .to_return(status: 200, body: issues.to_json, headers: { "Content-Type" => "application/json" })
    end
  end
end
