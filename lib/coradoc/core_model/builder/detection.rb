# frozen_string_literal: true

module Coradoc
  module CoreModel
    class Builder
      # Detection module for Builder
      #
      # Contains methods for detecting element types and extracting
      # information from AST structures.
      #
      # @api private
      module Detection
        # Detect the type of element from AST structure
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

        # Detect block type for specialized block creation
        def detect_block_type(ast)
          return :annotation if extract_annotation_type(ast)

          delimiter = ast[:delimiter]&.to_s
          return :annotation if delimiter && annotation_delimiters.include?(delimiter[0])

          return :list if ast[:marker] && list_markers.include?(ast[:marker].to_s)

          :generic
        end

        # Check if AST has header structure
        def has_header_structure?(ast)
          ast.key?(:title) && (ast.key?(:author) || ast.key?(:revision))
        end

        # Check if AST has section structure
        def has_section_structure?(ast)
          ast.key?(:title) && ast.key?(:level)
        end

        # Check if AST has block structure
        def has_block_structure?(ast)
          ast.key?(:delimiter) || ast.key?(:lines)
        end

        # Check if AST has inline structure
        def has_inline_structure?(ast)
          inline_format_types.any? { |type| ast.key?(type) }
        end

        # Extract annotation type from AST
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

          if attr_list.is_a?(Hash) && attr_list[:named]
            named = Array(attr_list[:named])
            reviewer_attr = named.find do |n|
              n.is_a?(Hash) && n[:key] == 'reviewer'
            end
            return 'reviewer' if reviewer_attr
          end

          nil
        end

        # Extract annotation label
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

        # Detect marker type for lists
        def detect_marker_type(ast)
          marker = ast[:marker]&.to_s
          return 'asterisk' if marker&.start_with?('*')
          return 'dash' if marker&.start_with?('-')
          return 'numbered' if marker&.match?(/^\d+\./) || marker&.start_with?('.')
          return 'labeled' if marker&.end_with?('::')

          'asterisk'
        end

        # Detect marker level
        def detect_marker_level(ast)
          marker = ast[:marker]&.to_s
          return marker.length if marker&.match?(/^[*.]+$/)

          1
        end

        # Detect inline format type
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

        # Detect if inline formatting is constrained
        def detect_constrained(ast, format_type)
          if format_type.end_with?('_constrained')
            return true
          elsif format_type.end_with?('_unconstrained')
            return false
          end

          key = "#{format_type}_constrained".to_sym
          return true if ast.key?(key)

          unconstrained_key = "#{format_type}_unconstrained".to_sym
          return false if ast.key?(unconstrained_key)

          true
        end

        # Extract level from section AST
        def extract_level(ast)
          if ast[:level]
            level_str = ast[:level].to_s
            return level_str.length - 1 if level_str.start_with?('=')
            return level_str.to_i if level_str.match?(/^\d+$/)
          end

          1
        end

        # List of annotation types
        def annotation_types
          %w[note warning caution important tip reviewer sidebar]
        end

        # List of annotation delimiters (first character)
        def annotation_delimiters
          %w[* / =]
        end

        # List of list markers
        def list_markers
          %w[* - . :: numbered]
        end

        # List of inline format types
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
