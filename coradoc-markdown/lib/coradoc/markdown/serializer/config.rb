# frozen_string_literal: true

require_relative 'flavor'

module Coradoc
  module Markdown
    class Serializer
      # Immutable serialization configuration.
      #
      # Created via `Serializer.build` with a flavor and overrides. Once
      # built, the Config is frozen and resolves capability strategies
      # (admonitions, autolinks, comments, etc.) by combining flavor
      # defaults with caller overrides.
      #
      # SSOT: the 5 spec-mandated options live here and nowhere else.
      # Strategy classes read their mode via `config.strategy_for(:capability)`.
      class Config
        ATTRIBUTES = %i[
          markdown_flavor
          admonition_style
          definition_list_nested
          suppress_comments
          autolinks
        ].freeze

        attr_reader(*ATTRIBUTES)

        def initialize(flavor: :gfm, **overrides)
          unless Flavor.known?(flavor)
            raise ArgumentError, "Unknown markdown_flavor: #{flavor.inspect}. " \
                                 "Known: #{Flavor.names.inspect}"
          end

          resolved = Flavor.resolve(flavor).merge(symbolize(overrides))
          validate_options!(resolved)

          @markdown_flavor = resolved.fetch(:markdown_flavor)
          @admonition_style = resolved.fetch(:admonition_style)
          @definition_list_nested = resolved.fetch(:definition_list_nested)
          @suppress_comments = resolved.fetch(:suppress_comments)
          @autolinks = resolved.fetch(:autolinks)

          freeze
        end

        def to_h
          ATTRIBUTES.to_h { |k| [k, public_send(k)] }
        end

        def with(overrides)
          self.class.new(**to_h.merge(symbolize(overrides)))
        end

        private

        def symbolize(hash)
          hash.to_h { |k, v| [k.to_sym, v] }
        end

        def validate_options!(resolved)
          unless %i[github container html gfm_alert].include?(resolved.fetch(:admonition_style))
            raise ArgumentError, "Unknown admonition_style: #{resolved[:admonition_style].inspect}"
          end
          unless %i[html flatten].include?(resolved.fetch(:definition_list_nested))
            raise ArgumentError, "Unknown definition_list_nested: #{resolved[:definition_list_nested].inspect}"
          end
          unless [true, false].include?(resolved.fetch(:suppress_comments))
            raise ArgumentError, "suppress_comments must be boolean"
          end
          unless [true, false].include?(resolved.fetch(:autolinks))
            raise ArgumentError, "autolinks must be boolean"
          end
        end
      end
    end
  end
end
