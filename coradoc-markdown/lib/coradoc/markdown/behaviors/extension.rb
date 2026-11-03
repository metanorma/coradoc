# frozen_string_literal: true

module Coradoc
  module Markdown
    module Behaviors
      # Hand-written behavior for the kramdown Extension model.
      module Extension
        # Known extension types
        TYPES = {
          toc: :toc,
          options: :options,
          comment: :comment,
          nomarkdown: :nomarkdown,
          ignore: :ignore,
          if: :conditional,
          endif: :conditional
        }.freeze

        def self.prepended(base)
          base.extend(ClassMethods)
        end

        # Factory helpers for common extensions.
        module ClassMethods
          # @param options [Hash] TOC options (levels, etc.)
          def toc(options = {})
            new(name: :toc, options: hash_to_named(options))
          end

          # @param options [Hash] Parser options
          def options(options = {})
            new(name: :options, options: hash_to_named(options))
          end

          # @param content [String] Comment content
          def comment(content = '')
            new(name: :comment, content: content)
          end

          # @param content [String] Raw content to pass through
          def nomarkdown(content)
            new(name: :nomarkdown, content: content)
          end

          private

          def hash_to_named(hash)
            return [] if hash.nil? || hash.empty?

            hash.map { |k, v| NamedValue.new(name: k.to_s, value: v.to_s) }
          end
        end

        # Check if this is a specific extension type
        # @param type [Symbol] The extension type
        # @return [Boolean]
        def type?(type)
          name.to_sym == type
        end

        # Check if this is a self-closing extension
        # @return [Boolean]
        def self_closing?
          content.nil? || content.empty?
        end
      end
    end
  end
end
