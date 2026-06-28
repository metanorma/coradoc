# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    class Builder
      module Detection
        def detect_element_type(ast)
          return :header if ast.key?(:header) || has_header_structure?(ast)
          return :section if ast.key?(:section) || has_section_structure?(ast)
          return :block if ast.key?(:block) || has_block_structure?(ast)
          return :list if ast.key?(:list) || ast.key?(:unordered) ||
                          ast.key?(:ordered) || ast.key?(:definition_list)
          return :paragraph if ast.key?(:paragraph)
          return :text if ast.key?(:text)
          return :attribute if ast.key?(:key) && ast.key?(:value)
          return :document_attributes if ast.key?(:document_attributes)
          return :inline if has_inline_structure?(ast)
          return :line_break if ast.key?(:line_break) && ast.keys.length == 1
          return :comment_line if ast.key?(:comment_line)
          return :comment_block if ast.key?(:comment_block)
          return :include if ast.key?(:include)
          return :table if ast.key?(:table)
          return :unparsed if ast.key?(:unparsed)
          return :tag if ast.key?(:tag)
          return :bibliography_entry if ast.key?(:bibliography_entry)

          nil
        end

        def detect_block_type(ast)
          return :annotation if extract_annotation_type(ast)
          return :list if ast[:marker] && list_markers.include?(ast[:marker].to_s)

          :generic
        end

        def has_header_structure?(ast)
          ast.key?(:title) && (ast.key?(:author) || ast.key?(:revision))
        end

        def has_section_structure?(ast)
          ast.key?(:title) && ast.key?(:level)
        end

        def has_block_structure?(ast)
          ast.key?(:delimiter) || ast.key?(:lines)
        end

        def has_inline_structure?(ast)
          inline_format_types.any? { |type| ast.key?(type) }
        end

        def detect_inline_format(ast)
          ast.each_key do |key|
            key_str = key.to_s
            return key_str if key_str.end_with?('_constrained', '_unconstrained')
          end

          inline_format_types.each do |format|
            return format.to_s if ast.key?(format)
          end

          'text'
        end

        def detect_constrained(ast, format_type)
          if format_type.end_with?('_constrained')
            return true
          elsif format_type.end_with?('_unconstrained')
            return false
          end

          key = :"#{format_type}_constrained"
          return true if ast.key?(key)

          unconstrained_key = :"#{format_type}_unconstrained"
          return false if ast.key?(unconstrained_key)

          true
        end

        def extract_level(ast)
          if ast[:level]
            level_str = ast[:level].to_s
            return level_str.length - 1 if level_str.start_with?('=')
            return level_str.to_i if level_str.match?(/^\d+$/)
          end

          1
        end

        def extract_annotation_type(ast)
          attr_list = ast[:attribute_list]
          if attr_list.is_a?(Hash) && attr_list[:positional]
            positional = Array(attr_list[:positional])
            annotation = positional.find do |p|
              annotation_types.include?(p.to_s.downcase)
            end
            return annotation.to_s.downcase if annotation
          end

          return ast[:admonition_type]&.to_s&.downcase if ast[:admonition_type]

          nil
        end

        def extract_annotation_label(ast)
          attr_list = ast[:attribute_list]
          return nil unless attr_list.is_a?(Hash)

          if attr_list[:named]
            named = Array(attr_list[:named])
            reviewer_attr = named.find do |n|
              n.is_a?(Hash) && n[:key] == 'reviewer'
            end
            return reviewer_attr[:value] if reviewer_attr
          end

          nil
        end

        def detect_marker_type(ast)
          marker = ast[:marker]&.to_s
          return 'unordered' if marker&.start_with?('*')
          return 'unordered' if marker&.start_with?('-')
          return 'ordered' if marker&.match?(/^\d+\./) || marker&.start_with?('.')
          return 'definition' if marker&.end_with?('::')

          'unordered'
        end

        def detect_marker_level(ast)
          marker = ast[:marker]&.to_s
          return marker.length if marker&.match?(/^[*.]+$/)

          1
        end

        def extract_text_content(content)
          case content
          when String
            content
          when Array
            content.map { |c| extract_text_content(c) }.join
          when Hash
            if content[:text]
              extract_text_content(content[:text])
            elsif content[:paragraph_text]
              extract_text_content(content[:paragraph_text])
            else
              content.values.map { |v| extract_text_content(v) }.join
            end
          else
            content.to_s
          end
        end

        def extract_inline_content(ast, format_type)
          content_key = format_type.to_sym
          content = ast[content_key] ||
                    ast[:"#{format_type}_constrained"] ||
                    ast[:"#{format_type}_unconstrained"]

          extract_text_content(content)
        end

        def annotation_types
          %w[note warning caution important tip reviewer sidebar]
        end

        def list_markers
          %w[* - . ::]
        end

        def inline_format_types
          %i[bold italic monospace superscript subscript highlight span link
             cross_reference bold_constrained bold_unconstrained
             italic_constrained italic_unconstrained monospace_constrained
             monospace_unconstrained]
        end
      end
    end
  end
end
