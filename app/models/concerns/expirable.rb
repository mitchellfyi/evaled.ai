# frozen_string_literal: true

module Expirable
  extend ActiveSupport::Concern

  included do
    scope :not_expired, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }
  end

  def expired?
    expires_at.present? && expires_at < Time.current
  end
end
