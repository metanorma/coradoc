module Coradoc
  module Element
    module Inline
      class Citation < Base
        attr_accessor :cross_reference, :comment

        declare_children :cross_reference, :comment

        def initialize(cross_reference, comment = nil)
          @cross_reference = cross_reference
          @comment = comment
        end

        def to_adoc
          adoc = "[.source]\n"
          adoc << @cross_reference.to_adoc
          adoc << Coradoc::Generator.gen_adoc(@comment) if @comment
          adoc
        end
      end
    end
  end
end
