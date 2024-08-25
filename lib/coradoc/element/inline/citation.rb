module Coradoc
  module Element
    module Inline
      class Citation < Base
        attr_accessor :cross_reference, :comment

        declare_children :cross_reference, :comment

        def initialize(opts = {})
          @cross_reference = opts.fetch(:cross_reference, nil)
          @comment = opts.fetch(:comment, nil)
        end

        def to_adoc
          adoc = "[.source]\n"
          adoc << @cross_reference.to_adoc if @cross_reference
          adoc << "\n" if @cross_reference && !@comment
          adoc << Coradoc::Generator.gen_adoc(@comment) if @comment
          adoc
        end
      end
    end
  end
end
