# frozen_string_literal: true

module Coradoc
  module Markdown
    module Schema
      # Exhaustive IR-parity diff between two class sets, normally the
      # hand-written models and the schema-generated classes.
      #
      # Compares, per class: presence, superclass, the ordered attribute
      # list and, per attribute, its type, collection flag and default.
      # Returns human-readable difference strings; empty means parity.
      class Parity
        # Differences accepted on purpose, each a defect of the hand-written
        # models rather than of the schema.
        #
        # Base declares `attribute :attributes, NamedValue`, and NamedValue
        # < Base, so NamedValue is autoloaded while Base is half-defined: the
        # hand-written NamedValue ends up WITHOUT the inherited `attributes`
        # attribute (when Heading loads first), or the require raises NameError
        # (when NamedValue loads first). The generated NamedValue always has it.
        KNOWN_DIFFERENCES = ['NamedValue.attributes: unexpected'].freeze

        # @param expected [Module] namespace holding the reference classes
        # @param actual [Module] namespace holding the classes under test
        # @param names [Array<String>] class names to compare
        # @param except [Array<String>] differences to ignore
        def self.diff(expected:, actual:, names:, except: KNOWN_DIFFERENCES)
          new(expected, actual).diff(names) - except
        end

        def initialize(expected, actual)
          @expected = expected
          @actual = actual
        end

        def diff(names)
          names.flat_map { |name| class_diff(name) }
        end

        private

        def class_diff(name)
          want = lookup(@expected, name)
          got = lookup(@actual, name)
          return ["#{name}: missing from #{@expected}"] unless want
          return ["#{name}: missing from #{@actual}"] unless got

          superclass_diff(name, want, got) + attributes_diff(name, want, got)
        end

        def lookup(namespace, name)
          namespace.const_get(name, false)
        rescue NameError
          nil
        end

        def superclass_diff(name, want, got)
          return [] if short(want.superclass) == short(got.superclass)

          ["#{name}: superclass #{short(want.superclass)} != #{short(got.superclass)}"]
        end

        def attributes_diff(name, want, got)
          wa = want.attributes
          ga = got.attributes
          diffs = []
          diffs << "#{name}: attribute order #{wa.keys} != #{ga.keys}" if wa.keys != ga.keys && wa.keys.sort == ga.keys.sort
          (wa.keys - ga.keys).each { |a| diffs << "#{name}.#{a}: missing" }
          (ga.keys - wa.keys).each { |a| diffs << "#{name}.#{a}: unexpected" }
          (wa.keys & ga.keys).each { |a| diffs.concat(attribute_diff("#{name}.#{a}", wa[a], ga[a])) }
          diffs
        end

        def attribute_diff(label, want, got)
          facets = facets_of(want)
          other = facets_of(got)
          facets.filter_map do |facet, value|
            "#{label}: #{facet} #{value.inspect} != #{other[facet].inspect}" unless value == other[facet]
          end
        end

        def facets_of(attribute)
          { type: short(attribute.type), collection: attribute.collection?, default: default_of(attribute) }
        end

        def default_of(attribute)
          register = Lutaml::Model::Config.default_register
          return :none unless attribute.default_set?(register)

          attribute.default(register)
        end

        # Class identity is compared by unqualified name so Coradoc::Markdown::X
        # and Coradoc::Markdown::Generated::X are the same type.
        def short(type)
          type.to_s.split('::').last
        end
      end
    end
  end
end
