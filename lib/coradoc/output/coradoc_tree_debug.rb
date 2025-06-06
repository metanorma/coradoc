module Coradoc
  module Output
    module CoradocTreeDebug
      def self.processor_id
        :coradoc_tree_debug
      end

      def self.processor_match?(_filename)
        false
      end

      def self.processor_execute(input, _options = {})
        out = StringIO.new
        PP.pp(input, out)
        { nil => out.string }
      end

      Coradoc::Output.define(self)
    end
  end
end
