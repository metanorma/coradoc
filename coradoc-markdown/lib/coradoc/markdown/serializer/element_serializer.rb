# frozen_string_literal: true

module Coradoc
  module Markdown
    class Serializer
      # Base class for element serializers. Subclasses declare:
      # - `handles_type TypeClass` — the model class (or ancestor) they accept
      # - `call(element, ctx)` — the actual serialization
      #
      # `handles?` defaults to `is_a?(handles_type)`; override for finer
      # conditional dispatch (e.g. "I handle DefinitionList only when nested").
      class ElementSerializer
        class << self
          def handles_type(klass = nil)
            if klass
              @handles_type = klass
              self
            else
              @handles_type || (superclass.respond_to?(:handles_type) ? superclass.handles_type : nil)
            end
          end

          def handles?(_element)
            true
          end

          def call(...)
            new.call(...)
          end
        end

        def call(_element, _ctx)
          raise NotImplementedError, "#{self.class.name}#call not implemented"
        end

        def handles?(element)
          self.class.handles?(element)
        end

        def handles_type
          self.class.handles_type
        end
      end
    end
  end
end
