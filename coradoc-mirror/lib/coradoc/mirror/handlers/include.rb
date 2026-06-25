# frozen_string_literal: true

module Coradoc
  module Mirror
    module Handlers
      # Include directive handler.
      #
      # Emits a ProseMirror-compatible +include+ node carrying the
      # target path and parsed options as typed attrs. Graph-mode
      # preservation: the node survives serialization and round-trips
      # back to a +CoreModel::Include+ via the reverse builder.
      module Include
        def self.call(element, context:)
          Node::Include.new(attrs: build_attrs(element))
        end

        class << self
          private

          def build_attrs(element)
            options = element.options
            Node::Include::Attrs.new(
              target: element.target,
              tags: tags_value(options),
              lines: options&.lines_spec,
              leveloffset: leveloffset_value(options),
              indent: options&.indent,
              file_encoding: options&.file_encoding,
              raw_options: element.raw_options
            )
          end

          def tags_value(options)
            return [] unless options

            options.tags
          end

          def leveloffset_value(options)
            return nil unless options&.leveloffset

            options.leveloffset.to_s
          end
        end
      end
    end
  end
end
