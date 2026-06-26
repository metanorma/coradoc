# frozen_string_literal: true

require 'lutaml/model'

module Coradoc
  module Reference
    # Scheme-aware locator targeting a Content node.
    #
    # An Address is one of six built-in schemes — +:anchor+, +:path+,
    # +:scoped_path+, +:url+, +:doi+, +:isbn+ — selected by heuristic on
    # parse or by an explicit +hint:+. External gems register additional
    # schemes via +Address.register_scheme+ (OCP).
    #
    #   Address.parse("foo")               # => anchor "foo"
    #   Address.parse("ELF-5005-1#sec-3")  # => path "ELF-5005-1", fragment "sec-3"
    #   Address.parse("ELF:5005:1#sec-3")  # => scoped_path scope "ELF"
    #   Address.parse("https://x.y/z")     # => url
    #   Address.parse("10.1234/abc")       # => doi
    #   Address.parse("ISBN 978-1-2-3")    # => isbn
    #
    # Addresses are value types: two addresses are equal iff every
    # attribute matches. Round-trip via +to_s+.
    class Address < Lutaml::Model::Serializable
      class ParseError < Coradoc::Error; end
      class UnknownSchemeError < Coradoc::Error; end

      attribute :scheme, :string
      attribute :target, :string
      attribute :fragment, :string
      attribute :version, :string
      attribute :scope, :string

      autoload :Url, "#{__dir__}/address/url"
      autoload :Doi, "#{__dir__}/address/doi"
      autoload :Isbn, "#{__dir__}/address/isbn"
      autoload :ScopedPath, "#{__dir__}/address/scoped_path"
      autoload :Path, "#{__dir__}/address/path"
      autoload :Anchor, "#{__dir__}/address/anchor"

      BUILTIN_SCHEME_ORDER = %i[url doi isbn scoped_path path anchor].freeze

      class << self
        def parse(raw, hint: nil)
          Scheme.ensure_builtins_registered!
          mod = hint ? Scheme.for(hint) : Scheme.match(raw)
          unless mod
            raise ParseError,
                  "Cannot determine address scheme for #{raw.inspect}"
          end
          mod.parse(raw)
        end

        def register_scheme(mod)
          Scheme.register(mod)
        end

        def scheme_names
          Scheme.ensure_builtins_registered!
          Scheme.names
        end
      end

      def to_s
        Scheme.ensure_builtins_registered!
        mod = Scheme.for(scheme)
        unless mod
          raise UnknownSchemeError,
                "No registered scheme for #{scheme.inspect}. " \
                "Registered: #{Scheme.names.inspect}"
        end
        mod.serialize(self)
      end

      def ==(other)
        return false unless other.is_a?(Address)

        comparable_attributes.all? { |a| public_send(a) == other.public_send(a) }
      end
      alias eql? ==

      def hash
        comparable_attributes.map { |a| public_send(a) }.hash
      end

      private

      def comparable_attributes
        %i[scheme target fragment version scope]
      end

      # Registry of scheme modules. Each module provides:
      #   scheme_name      -> Symbol
      #   matches?(raw)    -> Boolean
      #   parse(raw)       -> Address
      #   serialize(addr)  -> String
      module Scheme
        @registered = []
        @builtins_registered = false

        class << self
          def register(mod)
            @registered.delete_if { |m| m.scheme_name == mod.scheme_name }
            @registered << mod
          end

          def names
            @registered.map(&:scheme_name)
          end

          def for(name)
            @registered.find { |m| m.scheme_name == name.to_sym }
          end

          def match(raw)
            @registered.find { |m| m.matches?(raw) }
          end

          def ensure_builtins_registered!
            return if @builtins_registered

            BUILTIN_SCHEME_ORDER.each do |name|
              const_name = name.to_s.split('_').map(&:capitalize).join
              register(Address.const_get(const_name))
            end
            @builtins_registered = true
          end

          def reset!
            @registered.clear
            @builtins_registered = false
          end
        end
      end
    end
  end
end
