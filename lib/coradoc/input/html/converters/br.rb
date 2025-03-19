module Coradoc::Input::Html
  module Converters
    class Br < Base
      def to_coradoc(_node, _state = {})
        Coradoc::Element::Inline::HardLineBreak.new
      end
    end

    register :br, Br.new
  end
end
