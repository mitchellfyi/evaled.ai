# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

module Tier1
  class CodingEvalHarnessTest < ActiveSupport::TestCase
    setup do
      @agent = create(:agent)
      @task = create(:eval_task)
      # Stub the task to have initial_files, test_files, test_command
      @task.define_singleton_method(:initial_files) { { "main.rb" => "# Code here" } }
      @task.define_singleton_method(:test_files) { { "test.rb" => "# Tests" } }
      @task.define_singleton_method(:test_command) { "echo '1 passed, 0 failed'" }
      WebMock.enable!
    end

    teardown do
      WebMock.disable!
      cleanup_sandboxes
    end

    # Result structure tests
    test "run returns Result struct" do
      harness = CodingEvalHarness.new(@agent, @task)
      result = harness.run

      assert_kind_of CodingEvalHarness::Result, result
    end

    test "Result has expected attributes" do
      harness = CodingEvalHarness.new(@agent, @task)
      result = harness.run

      assert_respond_to result, :completed
      assert_respond_to result, :tests_passed
      assert_respond_to result, :tests_total
      assert_respond_to result, :accuracy
      assert_respond_to result, :duration_ms
      assert_respond_to result, :error
      assert_respond_to result, :agent_output
    end

    test "completed is true for successful run" do
      harness = CodingEvalHarness.new(@agent, @task)
      result = harness.run

      assert result.completed
    end

    test "duration_ms is positive" do
      harness = CodingEvalHarness.new(@agent, @task)
      result = harness.run

      assert result.duration_ms >= 0
    end

    # Sandbox tests
    test "creates sandbox directory" do
      harness = CodingEvalHarness.new(@agent, @task)

      # Access private method to test
      harness.send(:setup_sandbox)
      sandbox_path = harness.instance_variable_get(:@sandbox_path)

      assert File.directory?(sandbox_path)
    end

    test "cleans up sandbox after run" do
      harness = CodingEvalHarness.new(@agent, @task)
      harness.run

      sandbox_path = harness.instance_variable_get(:@sandbox_path)
      # Sandbox should be cleaned up
      assert_not sandbox_path&.exist?
    end

    test "sandbox_id is unique per run" do
      harness1 = CodingEvalHarness.new(@agent, @task)
      harness2 = CodingEvalHarness.new(@agent, @task)

      id1 = harness1.send(:sandbox_id)
      id2 = harness2.send(:sandbox_id)

      assert_not_equal id1, id2
    end

    # Initial state tests
    test "load_initial_state creates files in sandbox" do
      harness = CodingEvalHarness.new(@agent, @task)
      harness.send(:setup_sandbox)
      harness.send(:load_initial_state)

      sandbox_path = harness.instance_variable_get(:@sandbox_path)
      assert File.exist?(sandbox_path.join("main.rb"))
      assert File.exist?(sandbox_path.join("test.rb"))
    ensure
      FileUtils.rm_rf(sandbox_path) if sandbox_path
    end

    test "load_initial_state handles nested paths" do
      task = create(:eval_task,
        initial_files: { "src/lib/helper.rb" => "module Helper; end" }
      )
      harness = CodingEvalHarness.new(@agent, task)
      harness.send(:setup_sandbox)
      harness.send(:load_initial_state)

      sandbox_path = harness.instance_variable_get(:@sandbox_path)
      assert File.exist?(sandbox_path.join("src/lib/helper.rb"))
    ensure
      sandbox_path = harness.instance_variable_get(:@sandbox_path)
      FileUtils.rm_rf(sandbox_path) if sandbox_path
    end

    # Agent output parsing tests
    test "parse_agent_output extracts file changes" do
      harness = CodingEvalHarness.new(@agent, @task)

      output = <<~OUTPUT
        Here is my solution:

        ```main.rb
        def add(a, b)
          a + b
        end
        ```
      OUTPUT

      changes = harness.send(:parse_agent_output, output)

      assert changes.key?("main.rb")
      assert_includes changes["main.rb"], "def add(a, b)"
    end

    test "parse_agent_output handles multiple files" do
      harness = CodingEvalHarness.new(@agent, @task)

      output = <<~OUTPUT
        ```file1.rb
        content1
        ```

        ```file2.rb
        content2
        ```
      OUTPUT

      changes = harness.send(:parse_agent_output, output)

      assert_equal 2, changes.size
      assert changes.key?("file1.rb")
      assert changes.key?("file2.rb")
    end

    test "parse_agent_output ignores language-only code blocks" do
      harness = CodingEvalHarness.new(@agent, @task)

      output = <<~OUTPUT
        Here's an example:

        ```ruby
        puts "hello"
        ```
      OUTPUT

      changes = harness.send(:parse_agent_output, output)

      assert_empty changes
    end

    test "parse_agent_output handles various language markers" do
      harness = CodingEvalHarness.new(@agent, @task)

      languages = %w[ruby python javascript js ts go rust java c cpp sh bash json yaml yml html css sql]

      languages.each do |lang|
        output = "```#{lang}\ncode\n```"
        changes = harness.send(:parse_agent_output, output)
        assert_empty changes, "Should ignore #{lang} code block"
      end
    end

    # Path sanitization tests
    test "sanitize_path removes directory traversal" do
      harness = CodingEvalHarness.new(@agent, @task)

      assert_equal "etc/passwd", harness.send(:sanitize_path, "../../../etc/passwd")
      assert_equal "file.rb", harness.send(:sanitize_path, "../../file.rb")
    end

    test "sanitize_path removes leading slash" do
      harness = CodingEvalHarness.new(@agent, @task)

      assert_equal "etc/passwd", harness.send(:sanitize_path, "/etc/passwd")
    end

    # Test result parsing tests
    test "parse_test_results handles RSpec format" do
      harness = CodingEvalHarness.new(@agent, @task)

      output = "Finished in 1.5 seconds\n10 examples, 2 failures"
      status = OpenStruct.new(success?: false)

      results = harness.send(:parse_test_results, output, status)

      assert_equal 8, results[:passed]
      assert_equal 10, results[:total]
    end

    test "parse_test_results handles Jest format" do
      harness = CodingEvalHarness.new(@agent, @task)

      output = "Tests: 2 failed, 8 passed, 10 total"
      status = OpenStruct.new(success?: false)

      results = harness.send(:parse_test_results, output, status)

      assert_equal 8, results[:passed]
      assert_equal 10, results[:total]
    end

    test "parse_test_results handles pytest format" do
      harness = CodingEvalHarness.new(@agent, @task)

      output = "====== 8 passed, 2 failed ======"
      status = OpenStruct.new(success?: false)

      results = harness.send(:parse_test_results, output, status)

      assert_equal 8, results[:passed]
      assert_equal 10, results[:total]
    end

    test "parse_test_results handles Go test format" do
      harness = CodingEvalHarness.new(@agent, @task)

      output = "ok   package1\nok   package2\nFAIL package3"
      status = OpenStruct.new(success?: false)

      results = harness.send(:parse_test_results, output, status)

      assert_equal 2, results[:passed]
      assert_equal 3, results[:total]
    end

    test "parse_test_results falls back to exit status" do
      harness = CodingEvalHarness.new(@agent, @task)

      output = "All tests passed!"
      status = OpenStruct.new(success?: true)

      results = harness.send(:parse_test_results, output, status)

      assert_equal 1, results[:passed]
      assert_equal 1, results[:total]
    end

    # Test command detection tests
    test "detect_test_command finds npm test for package.json" do
      harness = CodingEvalHarness.new(@agent, @task)
      harness.send(:setup_sandbox)
      sandbox_path = harness.instance_variable_get(:@sandbox_path)

      File.write(sandbox_path.join("package.json"), "{}")

      command = harness.send(:detect_test_command)

      assert_equal "npm test", command
    ensure
      FileUtils.rm_rf(sandbox_path) if sandbox_path
    end

    test "detect_test_command finds rspec for Gemfile" do
      harness = CodingEvalHarness.new(@agent, @task)
      harness.send(:setup_sandbox)
      sandbox_path = harness.instance_variable_get(:@sandbox_path)

      File.write(sandbox_path.join("Gemfile"), "source 'https://rubygems.org'")

      command = harness.send(:detect_test_command)

      assert_equal "bundle exec rspec", command
    ensure
      FileUtils.rm_rf(sandbox_path) if sandbox_path
    end

    test "detect_test_command finds pytest for setup.py" do
      harness = CodingEvalHarness.new(@agent, @task)
      harness.send(:setup_sandbox)
      sandbox_path = harness.instance_variable_get(:@sandbox_path)

      File.write(sandbox_path.join("setup.py"), "# setup")

      command = harness.send(:detect_test_command)

      assert_equal "pytest", command
    ensure
      FileUtils.rm_rf(sandbox_path) if sandbox_path
    end

    test "detect_test_command finds go test for go.mod" do
      harness = CodingEvalHarness.new(@agent, @task)
      harness.send(:setup_sandbox)
      sandbox_path = harness.instance_variable_get(:@sandbox_path)

      File.write(sandbox_path.join("go.mod"), "module test")

      command = harness.send(:detect_test_command)

      assert_equal "go test ./...", command
    ensure
      FileUtils.rm_rf(sandbox_path) if sandbox_path
    end

    # Prompt building tests
    test "build_agent_prompt includes task prompt" do
      harness = CodingEvalHarness.new(@agent, @task)

      prompt = harness.send(:build_agent_prompt)

      assert_includes prompt, @task.prompt
    end

    test "build_agent_prompt includes initial files" do
      harness = CodingEvalHarness.new(@agent, @task)

      prompt = harness.send(:build_agent_prompt)

      assert_includes prompt, "main.rb"
    end

    test "format_files_for_prompt handles empty files" do
      harness = CodingEvalHarness.new(@agent, @task)

      formatted = harness.send(:format_files_for_prompt, nil)

      assert_equal "No initial files.", formatted
    end

    # Accuracy calculation tests
    test "build_result calculates accuracy correctly" do
      harness = CodingEvalHarness.new(@agent, @task)

      result = harness.send(:build_result,
        completed: true,
        tests_passed: 8,
        tests_total: 10
      )

      assert_equal 0.8, result.accuracy
    end

    test "build_result handles zero total tests" do
      harness = CodingEvalHarness.new(@agent, @task)

      result = harness.send(:build_result,
        completed: true,
        tests_passed: 0,
        tests_total: 0
      )

      assert_equal 0.0, result.accuracy
    end

    # Error handling tests
    test "run handles sandbox errors gracefully when setup fails" do
      harness = CodingEvalHarness.new(@agent, @task)

      # Stub to raise SandboxError at sandbox setup
      harness.define_singleton_method(:setup_sandbox) do
        raise CodingEvalHarness::SandboxError, "Permission denied for sandbox"
      end

      result = harness.run

      assert_not result.completed
      assert_includes result.error, "Permission denied"
    end

    # HTTP agent tests - test internal method with mock agent having api_endpoint method
    test "execute_http_agent_request handles successful response" do
      # Create a mock agent that has api_endpoint
      mock_agent = OpenStruct.new(
        api_endpoint: "https://api.test.com/agent",
        api_key: "test-key",
        id: 1
      )
      harness = CodingEvalHarness.new(mock_agent, @task)

      stub_request(:post, "https://api.test.com/agent")
        .with(headers: { "Authorization" => "Bearer test-key" })
        .to_return(
          status: 200,
          body: { response: "Here is the code" }.to_json
        )

      response = harness.send(:execute_http_agent_request, "Test prompt")

      assert response[:success]
      assert_equal "Here is the code", response[:output]
    end

    test "execute_http_agent_request handles timeout" do
      mock_agent = OpenStruct.new(
        api_endpoint: "https://api.test.com/agent",
        api_key: nil,
        id: 1
      )
      harness = CodingEvalHarness.new(mock_agent, @task)

      stub_request(:post, "https://api.test.com/agent")
        .to_timeout

      response = harness.send(:execute_http_agent_request, "Test prompt")

      assert_not response[:success]
      assert_includes response[:error], "timed out"
    end

    test "execute_local_agent returns success with empty output" do
      harness = CodingEvalHarness.new(@agent, @task)

      response = harness.send(:execute_local_agent, "Test prompt")

      assert response[:success]
      assert_equal "", response[:output]
    end

    private

    def cleanup_sandboxes
      sandbox_dir = CodingEvalHarness::SANDBOX_BASE_PATH
      FileUtils.rm_rf(sandbox_dir) if File.exist?(sandbox_dir)
    end
  end
end
