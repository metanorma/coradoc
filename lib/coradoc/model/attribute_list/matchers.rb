# frozen_string_literal: true

module Coradoc
  module Model
    class AttributeList < Base
      module Matchers
        def one(*args)
          One.new(*args)
        end

        class One
          def initialize(*possibilities)
            @possibilities = possibilities
          end

          def ===(other)
            @possibilities.any? { |i| i === other }
          end
        end

        def many(*args)
          Many.new(*args)
        end

        # TODO: Find a way to only reject some values but not all?
        class Many
          def initialize(*possibilities)
            @possibilities = possibilities
          end

          def ===(other)
            other = other.split(",") if other.is_a?(String)

            other.is_a?(Array) &&
              other.all? { |i| @possibilities.any? { |p| p === i } }
          end
        end
      end
    end
  end
end
