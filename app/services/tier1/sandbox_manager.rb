# frozen_string_literal: true
module Tier1
  class SandboxManager
    RESOURCE_LIMITS = {
      memory_mb: 512,
      cpu_seconds: 60,
      timeout_seconds: 300,
      max_processes: 10
    }.freeze

    def initialize
      @sandboxes = {}
    end

    def create_sandbox(language:, eval_run_id:)
      sandbox_id = SecureRandom.uuid
      sandbox_dir = Rails.root.join("tmp", "sandboxes", sandbox_id)

      FileUtils.mkdir_p(sandbox_dir)

      sandbox = Sandbox.new(
        id: sandbox_id,
        dir: sandbox_dir,
        language: language,
        eval_run_id: eval_run_id,
        limits: RESOURCE_LIMITS
      )

      @sandboxes[sandbox_id] = sandbox
      sandbox
    end

    def destroy_sandbox(sandbox_id)
      sandbox = @sandboxes.delete(sandbox_id)
      return unless sandbox

      FileUtils.rm_rf(sandbox.dir) if sandbox.dir.to_s.include?("sandboxes")
    end

    def cleanup_stale_sandboxes(older_than: 1.hour.ago)
      sandbox_root = Rails.root.join("tmp", "sandboxes")
      return unless Dir.exist?(sandbox_root)

      Dir.glob(sandbox_root.join("*")).each do |dir|
        if File.mtime(dir) < older_than
          FileUtils.rm_rf(dir)
        end
      end
    end
  end

  class Sandbox
    attr_reader :id, :dir, :language, :eval_run_id, :limits

    def initialize(id:, dir:, language:, eval_run_id:, limits:)
      @id = id
      @dir = dir
      @language = language
      @eval_run_id = eval_run_id
      @limits = limits
      @created_at = Time.current
    end

    def load_files(files)
      files.each do |path, content|
        full_path = File.join(@dir, path)
        FileUtils.mkdir_p(File.dirname(full_path))
        File.write(full_path, content)
      end
    end

    def run_command(command, timeout: nil)
      timeout ||= @limits[:timeout_seconds]

      Timeout.timeout(timeout) do
        stdout, stderr, status = Open3.capture3(
          command,
          chdir: @dir.to_s,
          rlimit_as: @limits[:memory_mb] * 1024 * 1024
        )

        {
          stdout: stdout,
          stderr: stderr,
          exit_code: status.exitstatus,
          success: status.success?
        }
      end
    rescue Timeout::Error
      { stdout: "", stderr: "Execution timed out", exit_code: -1, success: false }
    end

    def read_file(path)
      full_path = File.join(@dir, path)
      return nil unless File.exist?(full_path)
      File.read(full_path)
    end

    def write_file(path, content)
      full_path = File.join(@dir, path)
      FileUtils.mkdir_p(File.dirname(full_path))
      File.write(full_path, content)
    end

    def cleanup
      FileUtils.rm_rf(@dir) if @dir.to_s.include?("sandboxes")
    end
  end
end
