# frozen_string_literal: true

module Coradoc
  module Docx
    module Transform
      module Rules
        # Transforms w:r (Run) elements to InlineElement or String.
        #
        # Runs with formatting become CoreModel::InlineElement nodes.
        # Plain runs (no formatting properties) return their text directly.
        #
        # A single run may carry multiple formatting properties (e.g., bold +
        # italic). The most specific one wins for format_type, while the
        # text content is preserved.
        #
        # Uses effective_run_properties (when available) to resolve style
        # inheritance: explicit properties > paragraph style's rPr > basedOn chain.
        # Falls back to run.properties for backward compatibility.
        class RunRule < Rule
          def matches?(element)
            defined?(Uniword::Wordprocessingml::Run) &&
              element.is_a?(Uniword::Wordprocessingml::Run)
          end

          def apply(run, context)
            # Delegate non-text children (breaks, drawings, footnotes, etc.)
            non_text = extract_non_text_children(run, context)
            return non_text.first if non_text.any? && run.text.nil?

            text = run.text&.content.to_s
            return '' if text.empty? && non_text.empty?

            props = effective_props(run)
            return text if plain_run?(props)

            fmt = format_type(props, run, context)
            return text unless fmt

            CoreModel::InlineElement.new(
              format_type: fmt,
              content: text
            )
          end

          private

          def effective_props(run)
            if run.respond_to?(:effective_run_properties)
              ep = run.effective_run_properties
              return ep if ep
            end

            run.properties
          end

          def extract_non_text_children(run, context)
            result = []

            result << context.transform(run.break) if run.break

            result << context.transform(run.footnote_reference) if run.footnote_reference

            result << context.transform(run.endnote_reference) if run.endnote_reference

            run.drawings&.each do |drawing|
              result << context.transform(drawing)
            end

            # Tab character
            if run.respond_to?(:tab) && run.tab
              result << "\t"
            end

            # Inline math (m:oMath within a run)
            if run.respond_to?(:o_math) && run.o_math
              result << context.transform(run.o_math)
            end

            # Deleted text (tracked changes)
            if run.respond_to?(:del_text) && run.del_text
              text = run.del_text.respond_to?(:content) ? run.del_text.content.to_s : run.del_text.to_s
              result << CoreModel::InlineElement.new(
                format_type: 'strikethrough',
                content: text
              ) unless text.empty?
            end

            # Symbol (w:sym)
            if run.respond_to?(:sym) && run.sym
              sym = run.sym
              char = sym.respond_to?(:char) ? sym.char : nil
              result << char.to_s if char && !char.empty?
            end

            # No-break hyphen (U+2011)
            if run.respond_to?(:no_break_hyphen) && run.no_break_hyphen
              result << "\u2011"
            end

            # Soft hyphen (U+00AD)
            if run.respond_to?(:soft_hyphen) && run.soft_hyphen
              result << "\u00AD"
            end

            # Carriage return (w:cr) — treat as line break
            if run.respond_to?(:carriage_return) && run.carriage_return
              result << CoreModel::InlineElement.new(format_type: 'hard_line_break')
            end

            # Alternate content — extract preferred/fallback content
            if run.respond_to?(:alternate_content) && run.alternate_content
              result << extract_alternate_content(run.alternate_content, context)
            end

            result.compact
          end

          def extract_alternate_content(ac, context)
            # Prefer the fallback content (wc:w:bdoContent or mc:Fallback)
            content = if ac.respond_to?(:fallback) && ac.fallback
                        ac.fallback
                      elsif ac.respond_to?(:choice) && ac.choice
                        ac.choice
                      end

            return nil unless content

            # If the fallback/choice has paragraphs or runs, transform them
            if content.respond_to?(:runs)
              content.runs&.each { |r| context.transform(r) }
            elsif content.respond_to?(:paragraphs)
              content.paragraphs&.flat_map { |p| context.transform(p) }
            end
          end

          def plain_run?(props)
            return true unless props

            props.bold.nil? &&
              props.italic.nil? &&
              props.underline.nil? &&
              props.strike.nil? &&
              props.double_strike.nil? &&
              props.vertical_align.nil? &&
              props.small_caps.nil? &&
              props.caps.nil? &&
              props.hidden.nil? &&
              props.highlight.nil?
          end

          # Determine the dominant format type.
          # Checks rStyle-based semantic detection first, then explicit formatting.
          def format_type(props, run, context)
            return nil unless props

            # Check rStyle for semantic role
            if context.style_resolver.respond_to?(:run_semantic_role)
              role = context.style_resolver.run_semantic_role(run)
              case role
              when :monospace then return 'monospace'
              when :bold then return 'bold'
              when :italic then return 'italic'
              end
            end

            # Explicit formatting properties
            if bold?(props)
              'bold'
            elsif italic?(props)
              'italic'
            elsif props.underline
              'underline'
            elsif props.strike || props.double_strike
              'strikethrough'
            elsif subscript?(props)
              'subscript'
            elsif superscript?(props)
              'superscript'
            elsif props.small_caps
              'small'
            elsif props.caps
              'bold'
            elsif props.highlight
              'highlight'
            elsif props.hidden
              nil
            end
          end

          def bold?(props)
            props.bold && props.bold.value != false
          end

          def italic?(props)
            props.italic && props.italic.value != false
          end

          def subscript?(props)
            props.vertical_align&.value.to_s == 'subscript'
          end

          def superscript?(props)
            props.vertical_align&.value.to_s == 'superscript'
          end
        end
      end
    end
  end
end
