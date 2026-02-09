# frozen_string_literal: true
module Api
  module V1
    class TelemetryController < BaseController
      def create
        @telemetry_event = TelemetryEvent.new(telemetry_event_params)
        @telemetry_event.received_at ||= Time.current

        if @telemetry_event.save
          head :created
        else
          render json: { errors: @telemetry_event.errors.full_messages }, status: :unprocessable_content
        end
      end

      private

      def telemetry_event_params
        params.expect(telemetry_event: [:agent_id, :event_type, :received_at, metrics: {}, metadata: {}])
      end
    end
  end
end
