# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      # Handles AsciiDoc-specific formatting for attributes and special structures
      class Formatter
        class << self
          # Format an attribute list for AsciiDoc output
          # @param attrs [Coradoc::AsciiDoc::Model::AttributeList] Attribute list
          # @return [String] Formatted attribute list
          def attribute_list(attrs)
            return '' if attrs.nil?

            # Delegate to the attribute list's serialization
            attrs.respond_to?(:to_s) ? attrs.to_s : ''
          end

          # Format block attributes (anchor, role, options, etc.)
          # @param attrs [Hash, Coradoc::AsciiDoc::Model::AttributeList] Block attributes
          # @return [String] Formatted block attributes
          def block_attributes(attrs)
            return '' if attrs.nil? || (attrs.respond_to?(:empty?) && attrs.empty?)

            # If it's an AttributeList model, use its serialization
            return attribute_list(attrs) if attrs.is_a?(Coradoc::AsciiDoc::Model::AttributeList)

            # Otherwise format as hash
            lines = []

            # Handle anchor if present
            if attrs[:id] || attrs['id']
              id = attrs[:id] || attrs['id']
              lines << "[[#{id}]]"
            end

            # Handle other attributes
            attr_parts = []
            attrs.each do |key, value|
              next if [:id, 'id'].include?(key)

              attr_parts << case key
                            when :role, 'role'
                              ".#{value}"
                            when :options, 'options'
                              "[#{value}]"
                            else
                              "#{key}=#{value}"
                            end
            end

            lines << "[#{attr_parts.join(',')}]" unless attr_parts.empty?
            lines.join("\n")
          end

          # Format a section heading
          # @param level [Integer] Section level (1-6)
          # @param title [String] Section title
          # @param id [String, nil] Optional section ID
          # @return [String] Formatted section heading
          def section_heading(level, title, id = nil)
            prefix = '=' * level
            anchor = id ? "[[#{id}]]\n" : ''
            "#{anchor}#{prefix} #{title}"
          end

          # Format a block delimiter
          # @param type [Symbol] Block type (:example, :sidebar, :quote, etc.)
          # @return [String] Block delimiter
          def block_delimiter(type)
            case type
            when :example
              '===='
            when :sidebar
              '****'
            when :quote
              '____'
            when :listing, :literal
              '----'
            when :passthrough
              '++++'
            else
              '----'
            end
          end

          # Format an admonition
          # @param type [String] Admonition type (NOTE, TIP, etc.)
          # @param content [String] Admonition content
          # @return [String] Formatted admonition
          def admonition(type, content)
            "#{type.upcase}: #{content}"
          end

          # Format a list marker
          # @param type [Symbol] List type (:ordered, :unordered, :definition)
          # @param level [Integer] Nesting level
          # @param index [Integer, nil] Item index for ordered lists
          # @return [String] List marker
          def list_marker(type, level = 1, _index = nil)
            case type
            when :ordered
              "#{'.' * level} "
            when :unordered
              "#{'*' * level} "
            when :definition
              ''
            else
              '* '
            end
          end

          # Escape special AsciiDoc characters in text
          # Works by prepending a backslash to all delimiter characters
          # in the string that are adjacent to a whitespace.
          # @param text [String] Text to escape
          # @param escape_chars [Array<String>] Characters to escape by prepending backslash
          # @param pass_through [Array<String>] Characters to pass through using pass:[] macro
          # @return [String] Escaped text
          def escape_text(text, escape_chars: [], pass_through: [])
            return '' if text.nil?

            result = text.to_s.dup

            regex_chars = Regexp.escape(escape_chars.join)
            unless regex_chars.empty?
              result.gsub!(
                /((?<=\s)[#{regex_chars}]+)|([#{regex_chars}]+(?=\s))/
              ) do |match|
                match.chars.map { |c| "\\#{c}" }.join
              end
            end

            regex_pass = Regexp.escape(pass_through.join)
            result.gsub!(/([#{regex_pass}]+)/, '{pass:[\\1]}') unless regex_pass.empty?

            result
          end
        end
      end
    end
  end
end
