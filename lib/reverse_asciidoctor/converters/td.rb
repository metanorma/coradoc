module ReverseAsciidoctor
  module Converters
    class Td < Base
      def convert(node, state = {})
        id = node['id']
        content = treat_children(node, state)
        " #{content} |"
      end
    end

    register :td, Td.new
    register :th, Td.new
  end
end
