class SandboxCleanupJob < ApplicationJob
  queue_as :low

  def perform
    manager = Tier1::SandboxManager.new
    manager.cleanup_stale_sandboxes(older_than: 1.hour.ago)
  end
end
