# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Mirror
    module ReverseBuilder
      # Include directive: round-trips back to a CoreModel::Include link
      # node. The text graph is preserved through mirror_json → core.
      class Include < Base
        registers 'include'

        def build(node)
          attrs = node.attrs
          CoreModel::Include.new(
            target: attrs&.target,
            options: build_options(attrs),
            raw_options: attrs&.raw_options || ''
          )
        end

        private

        def build_options(attrs)
          return CoreModel::IncludeOptions.new unless attrs

          CoreModel::IncludeOptions.new(
            tags: Array(attrs.tags),
            tags_wildcard: attrs.tags == ['*'],
            tags_inverted: attrs.tags == ['**'],
            lines_spec: attrs.lines,
            leveloffset: parse_leveloffset(attrs.leveloffset),
            indent: attrs.indent,
            file_encoding: attrs.file_encoding
          )
        end

        def parse_leveloffset(raw)
          return nil if raw.nil? || raw.to_s.empty?

          Coradoc::CoreModel::IncludeLevelOffset.parse(raw.to_s)
        end
      end
    end
  end
end
