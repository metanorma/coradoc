# frozen_string_literal: true

module Coradoc
  module IncludeSelectors
    # Extracts regions delimited by +// tag::name[]+ / +// end::name[]+
    # markers from included content. Supports single, multiple,
    # wildcard (*), and inverted (**) selection.
    #
    # Tag markers themselves are never emitted as text (SPEC 2.8).
    # Unknown tag names yield empty content (SPEC 2.6). Nested tag
    # regions are included when an outer tag is selected (SPEC 2.7).
    #
    # Marker forms recognized:
    #   // tag::name[]      (AsciiDoc line comment)
    #   ## tag::name[]      (Markdown line comment, permissive)
    #
    # Markers may appear on their own line; they must be the first
    # non-whitespace token on that line (asciidoctor convention).
    module Tags
      MARKER_OPEN  = /\A[[:space:]]*(?:\/\/+|#+)[[:space:]]*tag::([^\[\]]+)\[[[:space:]]*\]/
      MARKER_CLOSE = /\A[[:space:]]*(?:\/\/+|#+)[[:space:]]*end::([^\[\]]+)\[[[:space:]]*\]/

      # @param text [String] raw included file content
      # @param options [Coradoc::CoreModel::IncludeOptions]
      # @return [String] filtered content
      def self.call(text, options:)
        return text unless options.tags?

        if options.tags_inverted
          inverted(text)
        elsif options.tags_wildcard
          wildcard(text)
        else
          named(text, options.tags)
        end
      end

      class << self
        private

        def scan_markers(text)
          markers = []
          text.each_line.with_index do |line, idx|
            if (m = MARKER_OPEN.match(line))
              markers << [:open, m[1].strip, idx]
            elsif (m = MARKER_CLOSE.match(line))
              markers << [:close, m[1].strip, idx]
            end
          end
          markers
        end

        def named(text, names)
          wanted_indices = selected_line_indices(text, names).to_set
          pick_lines(text, wanted_indices)
        end

        def selected_line_indices(text, wanted_names)
          markers = scan_markers(text)
          wanted = wanted_names.to_set
          open_stack = []
          emit = {}

          markers.each do |kind, name, idx|
            case kind
            when :open
              next unless wanted.include?(name)

              open_stack.push([name, idx])
            when :close
              next unless wanted.include?(name)

              open_idx = open_stack.rindex { |n, _| n == name }
              next unless open_idx

              _open_name, open_line = open_stack.delete_at(open_idx)
              (open_line + 1...idx).each { |i| emit[i] = true }
            end
          end

          emit.keys
        end

        def wildcard(text)
          markers = scan_markers(text)
          open_stack = []
          emit = {}

          markers.each do |kind, _name, idx|
            case kind
            when :open
              open_stack.push(idx)
            when :close
              next if open_stack.empty?

              open_line = open_stack.pop
              (open_line + 1...idx).each { |i| emit[i] = true }
            end
          end

          pick_lines(text, emit.keys.to_set)
        end

        def inverted(text)
          markers = scan_markers(text)
          open_stack = []
          excluded = {}

          markers.each do |kind, _name, idx|
            case kind
            when :open
              open_stack.push(idx)
            when :close
              next if open_stack.empty?

              open_line = open_stack.pop
              (open_line..idx).each { |i| excluded[i] = true }
            end
          end

          markers.each { |_kind, _name, idx| excluded[idx] = true }

          lines = text.lines
          kept = lines.each_with_index.reject { |_line, idx| excluded[idx] }
          kept.map(&:first).join
        end

        def pick_lines(text, wanted_indices)
          lines = text.lines
          lines.each_with_index.select { |_line, idx| wanted_indices.include?(idx) }
               .map(&:first).join
        end
      end
    end
  end
end

require 'set'
