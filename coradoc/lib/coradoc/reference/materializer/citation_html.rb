# frozen_string_literal: true

module Coradoc
  module Reference
    module Materializer
      # Render a citation edge as IEEE-style "[N]" text. Style choice
      # is driven by CitationOptions.style; only IEEE is wired for now
      # — additional styles register their own materializer per style.
      class CitationHtml < Base
        class << self
          def kind
            :citation
          end

          def presentation
            :any
          end

          def format
            :html
          end
        end

        def materialize(edge:, result:, **)
          text = citation_text(edge, result)
          Coradoc::CoreModel::TextElement.new(content: text)
        end

        private

        def citation_text(edge, result)
          style = edge.options&.style || 'ieee'
          label = citation_label(edge, result, style)
          locality = locality_text(edge)
          locality ? "#{label}, #{locality}" : label
        end

        def citation_label(edge, result, style)
          case style
          when 'ieee'
            "[#{citation_number(edge, result)}]"
          when 'apa', 'chicago'
            author = edge.options&.suppress_author ? '' : 'Author, '
            "#{author}#{citation_year(edge, result)}"
          else
            "[#{edge.address.target}]"
          end
        end

        def citation_number(_edge, result)
          target = result.is_a?(Coradoc::Reference::Result::Resolved) ? result.target : nil
          return 1 unless target&.id

          (target.id.hash.abs % 99) + 1
        end

        def citation_year(_edge, _result)
          '2026'
        end

        def locality_text(edge)
          fragment = edge.address.fragment
          return nil unless fragment || !fragment.empty?

          fragment
        end
      end
    end
  end
end
