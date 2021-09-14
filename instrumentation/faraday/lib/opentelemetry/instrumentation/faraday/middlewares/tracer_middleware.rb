# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

# require 'opentelemetry/common/http/request_attributes'
require 'opentelemetry/instrumentation_helpers'

module OpenTelemetry
  module Instrumentation
    module Faraday
      module Middlewares
        # TracerMiddleware propagates context and instruments Faraday requests
        # by way of its middlware system
        class TracerMiddleware < ::Faraday::Middleware
          include InstrumentationHelpers::HTTP::RequestAttributes

          HTTP_METHODS_SYMBOL_TO_STRING = {
            connect: 'CONNECT',
            delete: 'DELETE',
            get: 'GET',
            head: 'HEAD',
            options: 'OPTIONS',
            patch: 'PATCH',
            post: 'POST',
            put: 'PUT',
            trace: 'TRACE'
          }.freeze

          def call(env)
            http_method = HTTP_METHODS_SYMBOL_TO_STRING[env.method]
            attributes = span_creation_attributes(
              http_method: http_method, url: env.url
            )
            tracer.in_span(
              "HTTP #{http_method}", attributes: attributes, kind: :client
            ) do |span|
              OpenTelemetry.propagation.inject(env.request_headers)

              app.call(env).on_complete { |resp| trace_response(span, resp) }
            end
          end

          private

          attr_reader :app

          def span_creation_attributes(http_method:, url:)
            config = Faraday::Instrumentation.instance.config
            attributes = from_request(http_method, url, config)
            attributes['peer.service'] = config[:peer_service] if config[:peer_service]
            attributes.merge(OpenTelemetry::Common::HTTP::ClientContext.attributes)
          end

          def tracer
            Faraday::Instrumentation.instance.tracer
          end

          def trace_response(span, response)
            span.set_attribute('http.status_code', response.status)
            span.status = OpenTelemetry::Trace::Status.error unless (100..399).include?(response.status.to_i)
          end
        end
      end
    end
  end
end
