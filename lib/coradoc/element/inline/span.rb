module Coradoc
  module Element
    module Inline
      class Span < Base
        attr_accessor :text, :role

        declare_children :text

        def initialize(text, options = {})
          @text = text
          @role = options.fetch(:role, nil)
        end

        def to_adoc
          if @role
            "[.#{@role}]##{@text}#"
          else
            "#{@text}"
          end
        end
      end
    end
  end
end
