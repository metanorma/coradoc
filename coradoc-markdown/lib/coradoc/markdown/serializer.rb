# frozen_string_literal: true

require_relative 'serializer/builder'
require_relative 'serializer/flavor'

module Coradoc
  module Markdown
    # Serializer for Markdown Document models.
    #
    # Two equivalent entry points:
    #
    #   # Build a configured runner (preferred for non-default options)
    #   Serializer.build(:gfm) do |config|
    #     config.admonition_style = :container
    #     config.suppress_comments = false
    #   end.call(element)
    #
    #   # One-shot with overrides
    #   Serializer.call(element, markdown_flavor: :vitepress)
    #
    # The legacy `serialize(element, options = {})` class method is kept
    # as a thin alias for `call` so existing callers don't break.
    class Serializer
      class << self
        def build(flavor = Flavor::DEFAULT_FLAVOR, &block)
          builder = Builder.new(flavor)
          block&.call(builder)
          builder.runner
        end

        def call(element, **options)
          flavor = options.delete(:markdown_flavor) || options.delete(:flavor) || Flavor::DEFAULT_FLAVOR
          Builder.new(flavor).apply(options).call(element)
        end

        def serialize(element, options = {})
          call(element, **options)
        end

        def new(*)
          raise NoMethodError,
                'Coradoc::Markdown::Serializer is no longer instantiable. ' \
                'Use Serializer.build(:gfm) or Serializer.call(element).'
        end
      end
    end
  end
end
