class TelemetryEvent < ApplicationRecord
  belongs_to :agent

  validates :event_type, presence: true
  validates :received_at, presence: true

  before_validation :set_received_at, on: :create

  private

  def set_received_at
    self.received_at ||= Time.current
  end
end
