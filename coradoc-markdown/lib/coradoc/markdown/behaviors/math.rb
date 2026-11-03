# frozen_string_literal: true

module Coradoc
  module Markdown
    module Behaviors
      # Hand-written behavior for Math (block or inline).
      module Math
        def self.prepended(base)
          base.extend(ClassMethods)
        end

        # Constructors for the two math flavors.
        module ClassMethods
          # @param content [String] The math content
          # @return [Coradoc::Markdown::Math]
          def inline(content)
            new(content: content, inline: true)
          end

          def block(content)
            new(content: content, inline: false)
          end
        end

        # @return [Boolean]
        def inline?
          inline == true
        end
      end
    end
  end
end
