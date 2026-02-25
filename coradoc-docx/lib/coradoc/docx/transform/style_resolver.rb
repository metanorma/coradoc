# frozen_string_literal: true

module Coradoc
  module Docx
    module Transform
      # Resolves paragraph and run styles to semantic roles.
      #
      # OOXML paragraphs don't have explicit element types. Instead, their
      # meaning is determined by style references (e.g., "Heading1" → section)
      # or by formatting properties (e.g., numPr → list item).
      #
      # StyleResolver centralizes this detection so HeadingRule, ListItemRule,
      # and ParagraphRule don't duplicate the logic.
      #
      # The style map is built from the Uniword StylesConfiguration by walking
      # all style definitions and their basedOn chains.
      class StyleResolver
        HEADING_PATTERN = /^(heading|heading|h)\s*(\d+)$/i
        QUOTE_PATTERN = /\bquote\b/i
        CODE_PATTERN = /\b(code|source|listing)\b/i
        LITERAL_PATTERN = /\bliteral\b/i
        EXAMPLE_PATTERN = /\bexample\b/i

        # @param styles_configuration [Object, nil] Uniword styles configuration
        def initialize(styles_configuration)
          @config = styles_configuration
          @style_map = build_style_map(styles_configuration)
        end

        # Determine the semantic role of a paragraph
        #
        # @param paragraph [Uniword::Wordprocessingml::Paragraph]
        # @return [Symbol] :heading, :list_item, :quote, :source, :literal,
        #   :example, or :paragraph
        def semantic_role(paragraph)
          return :heading if heading?(paragraph)
          return :list_item if list_item?(paragraph)

          style_role = role_from_style(paragraph)
          return style_role if style_role

          :paragraph
        end

        # Check if paragraph is a heading
        # @param paragraph [Uniword::Wordprocessingml::Paragraph]
        # @return [Boolean]
        def heading?(paragraph)
          return false unless paragraph.properties

          style_name = resolve_style_name(paragraph)
          return true if style_name && HEADING_PATTERN.match?(style_name)

          # Check outline_level on paragraph properties
          ol = paragraph.properties.outline_level
          if ol
            ol_level = ol.respond_to?(:value) ? ol.value.to_i : ol.to_i
            return true if ol_level.positive?
          end

          # Check outline_level from style definition
          style = find_style_for_paragraph(paragraph)
          if style.respond_to?(:outline_level) && style.outline_level
            ol_val = style.outline_level
            ol_val = ol_val.respond_to?(:value) ? ol_val.value.to_i : ol_val.to_i
            return true if ol_val.positive?
          end

          false
        end

        # Get heading level (1-6) or nil
        # @param paragraph [Uniword::Wordprocessingml::Paragraph]
        # @return [Integer, nil]
        def heading_level(paragraph)
          style_name = resolve_style_name(paragraph)
          if style_name
            match = HEADING_PATTERN.match(style_name)
            return match[2].to_i if match
          end

          # Check outline_level on paragraph properties
          ol = paragraph.properties&.outline_level
          if ol
            level = ol.respond_to?(:value) ? ol.value.to_i : ol.to_i
            return level if level.positive?
          end

          nil
        end

        # Check if paragraph is a list item
        # @param paragraph [Uniword::Wordprocessingml::Paragraph]
        # @return [Boolean]
        def list_item?(paragraph)
          return false unless paragraph.properties

          num_id = paragraph.properties.num_id
          num_id.to_i.positive?
        end

        # Check if paragraph has a specific role based on style name
        # @param paragraph [Uniword::Wordprocessingml::Paragraph]
        # @return [Symbol, nil]
        def role_from_style(paragraph)
          style_name = resolve_style_name(paragraph)
          return nil unless style_name

          case style_name
          when QUOTE_PATTERN then :quote
          when CODE_PATTERN then :source
          when LITERAL_PATTERN then :literal
          when EXAMPLE_PATTERN then :example
          end
        end

        # Detect semantic role of a run based on its rStyle
        # @param run [Uniword::Wordprocessingml::Run]
        # @return [Symbol, nil]
        def run_semantic_role(run)
          return nil unless run.properties
          return nil unless run.properties.style

          style_name = resolve_run_style_name(run)
          return nil unless style_name

          case style_name
          when /\b(code|verbatim|teletype|keyboard)\b/i then :monospace
          when /\bstrong\b/i then :bold
          when /\b(emphasis|em)\b/i then :italic
          when /\bcitation\b/i then :italic
          end
        end

        private

        def resolve_style_name(paragraph)
          style_ref = paragraph.properties&.style
          return nil unless style_ref

          value = style_ref.respond_to?(:value) ? style_ref.value : style_ref.to_s
          return nil unless value

          # Check local style map first (for custom style aliases)
          mapped = @style_map[value]
          return mapped if mapped

          value
        end

        def resolve_run_style_name(run)
          style_ref = run.properties.style
          return nil unless style_ref

          value = style_ref.respond_to?(:value) ? style_ref.value : style_ref.to_s
          return nil unless value

          mapped = @style_map[value]
          mapped || value
        end

        def find_style_for_paragraph(paragraph)
          return nil unless @config

          style_id = style_id_from_paragraph(paragraph)
          return nil unless style_id

          if @config.respond_to?(:style_by_id)
            @config.style_by_id(style_id)
          elsif @config.respond_to?(:styles)
            @config.styles.find { |s| s.styleId == style_id }
          end
        end

        def style_id_from_paragraph(paragraph)
          style_ref = paragraph.properties&.style
          return nil unless style_ref

          style_ref.respond_to?(:value) ? style_ref.value : style_ref.to_s
        end

        def build_style_map(config)
          return {} unless config
          return {} unless config.respond_to?(:styles)

          map = {}
          config.styles.each do |style|
            id = style.styleId
            name = extract_style_name(style)
            next unless id && name

            map[id] = name

            # Detect custom heading styles by basedOn chain
            if heading_by_based_on?(config, style)
              level = heading_level_from_chain(config, style)
              map[id] = "Heading#{level}"
            end
          end

          map
        end

        def extract_style_name(style)
          return style.style_name if style.respond_to?(:style_name)

          name = style.name
          return nil unless name

          name.respond_to?(:val) ? name.val.to_s : name.to_s
        end

        def heading_by_based_on?(config, style)
          based_on = style.respond_to?(:based_on) ? style.based_on : nil
          return false unless based_on

          visited = Set.new
          current = style
          while current && !visited.include?(current.styleId)
            visited << current.styleId
            parent_id = current.respond_to?(:based_on) ? current.based_on : nil
            return true if parent_id && HEADING_PATTERN.match?(parent_id)

            break unless parent_id && config.respond_to?(:styles)

            current = config.styles.find { |s| s.styleId == parent_id }
          end

          false
        end

        def heading_level_from_chain(config, style)
          visited = Set.new
          current = style
          while current && !visited.include?(current.styleId)
            visited << current.styleId
            name = extract_style_name(current)
            if name
              match = HEADING_PATTERN.match(name)
              return match[2].to_i if match
            end

            parent_id = current.respond_to?(:based_on) ? current.based_on : nil
            break unless parent_id && config.respond_to?(:styles)

            current = config.styles.find { |s| s.styleId == parent_id }
          end

          1
        end
      end
    end
  end
end
