# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Parser
      module DocumentAttributes
        def attribute_name
          match('[a-zA-Z0-9_-]').repeat(1)
        end

        def attribute_value
          text | (str('') >> str("\n").absent?)
        end

        def document_attributes
          document_attribute.repeat(1)
                            .as(:document_attributes)
        end

        def document_attribute
          str(':') >> attribute_name.as(:key) >> str(':') >>
            # attribute_value itself already matches empty (its
            # zero-width branch), so the former `| str('')` fallback was
            # dead — ordered choice commits to attribute_value's empty
            # match first — and the VM's shadowed-alternative lint
            # (parsanol 1.3.55+) correctly rejects it.
            space? >> attribute_value.as(:value) >> (line_ending | eof?)
        end
      end
    end
  end
end
