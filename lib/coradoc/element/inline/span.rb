module Coradoc
  module Element
    module Inline
      class Span < Base
        attr_accessor :text, :role, :attributes, :unconstrained

        declare_children :text, :attributes

        def initialize(text:, role: nil, attributes: nil, unconstrained: false)
          @text = text
          @role = role
          @attributes = attributes
          @unconstrained = unconstrained
        end

        def to_adoc
          if @attributes
            attr_string = @attributes.to_adoc
            if @unconstrained
              "#{attr_string}###{@text}##"
            else
              "#{attr_string}##{@text}#"
            end
          elsif @role
            if @unconstrained
              "[.#{@role}]###{@text}##"
            else
              "[.#{@role}]##{@text}#"
            end
          else
            @text.to_s
          end
        end
      end
    end
  end
end
