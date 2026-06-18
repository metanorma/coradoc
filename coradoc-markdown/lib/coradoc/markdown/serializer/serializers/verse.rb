# frozen_string_literal: true

require_relative '../element_serializer'

module Coradoc
  module Markdown
    class Serializer
      module Serializers
        # Verse: blockquote with hard line breaks preserved. The verse
        # semantic is lost but line breaks survive.
        class Verse < ElementSerializer
          handles_type ::Coradoc::Markdown::Verse

          def call(element, _ctx)
            body = element.content.to_s
            attribution = element.attribution
            citetitle = element.citetitle
            attribution_line = if attribution && citetitle
                                 "\n>\n> — #{attribution}, <cite>#{citetitle}</cite>"
                               elsif attribution
                                 "\n>\n> — #{attribution}"
                               else
                                 ''
                               end
            body.lines.map { |line| "> #{line}".rstrip }.join("\n").concat(attribution_line)
          end
        end
      end
    end
  end
end
