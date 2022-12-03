# frozen_string_literal: true

require "test/unit"
require_relative "../lib/opentelemetry_sdk_rust"

class SDKTest < Test::Unit::TestCase
  def test_tracer_provider
    assert { !OpenTelemetry::SDK::Trace::TracerProvider.new.nil? }
    assert { !OpenTelemetry::SDK::Trace::TracerProvider.new.tracer("foo").nil? }
    assert { !OpenTelemetry::SDK::Trace::TracerProvider.new.tracer("foo", "1.2.3").nil? }
  end
end