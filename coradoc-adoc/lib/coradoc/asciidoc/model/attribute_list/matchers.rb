# frozen_string_literal: true

module Coradoc
  module AsciiDoc
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

          # NOTE: The Many matcher validates that all values in an array/string match
          # one of the specified possibilities. Currently accepts all matching values
          # without selective rejection - this may be enhanced in future versions.
          class Many
            def initialize(*possibilities)
              @possibilities = possibilities
            end

            def ===(other)
              other = other.split(',') if other.is_a?(String)

              other.is_a?(Array) &&
                other.all? { |i| @possibilities.any? { |p| p === i } }
            end
          end
        end
      end
    end
  end
end
