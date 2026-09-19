# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class PassThrough < Base
        INSTANCE = new

        def to_coradoc(node, _state = {})
          node.is_a?(Leptris::XML::Node) ? node.to_xml(no_decl: true) : node.to_s
        end
      end
    end
  end
end
