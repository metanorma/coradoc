# frozen_string_literal: true

require_relative 'config'
require_relative 'context'
require_relative 'registry'
require_relative 'registrations'
require_relative 'runner'

module Coradoc
  module Markdown
    class Serializer
      # Fluent builder for a configured serializer runner.
      #
      # Usage:
      #
      #   Serializer.build(:gfm) do |config|
      #     config.admonition_style = :container
      #     config.suppress_comments = false
      #   end.call(element)
      #
      # The block yields the Builder itself; assignments accumulate as
      # overrides and are frozen into a Config when `runner` (or `call`)
      # is invoked.
      class Builder
        attr_reader :flavor, :overrides

        def initialize(flavor = Flavor::DEFAULT_FLAVOR)
          @flavor = flavor
          @overrides = {}
        end

        Config::ATTRIBUTES.each do |attr|
          define_method("#{attr}=") do |value|
            @overrides[attr] = value
          end
        end

        def apply(hash)
          hash.each { |k, v| @overrides[k.to_sym] = v }
          self
        end

        def config
          @config ||= Config.new(flavor: flavor, **overrides)
        end

        def runner
          @runner ||= Runner.new(config: config, registry: Registrations.default_registry)
        end

        def call(element)
          runner.call(element)
        end
      end
    end
  end
end
