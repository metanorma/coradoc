# frozen_string_literal: true

require 'lutaml/model'

module Coradoc
  module Reference
    # Directed edge: a Content node references another Content via an Address.
    #
    # Every reference in coradoc — navigation, citation, hyperlink,
    # include, image, footnote — is one Edge with a different +kind+.
    # The kind is a label for materialization; resolution is kind-agnostic.
    #
    #   Edge.new(
    #     kind: :navigation,
    #     address: Address.parse("ELF-5005-1#sec-3"),
    #     source_id: "para-42",
    #     label: "Section 3"
    #   )
    class Edge < Lutaml::Model::Serializable
      autoload :Kind, "#{__dir__}/edge/kind"
      autoload :Options, "#{__dir__}/edge/options"
      autoload :NavigationOptions,
               "#{__dir__}/edge/navigation_options"
      autoload :CitationOptions,
               "#{__dir__}/edge/citation_options"
      autoload :LinkOptions, "#{__dir__}/edge/link_options"
      autoload :IncludeOptions, "#{__dir__}/edge/include_options"
      autoload :ImageRefOptions, "#{__dir__}/edge/image_ref_options"
      autoload :FootnoteRefOptions,
               "#{__dir__}/edge/footnote_ref_options"

      attribute :kind, :string
      attribute :address, Coradoc::Reference::Address
      attribute :source_id, :string
      attribute :label, :string
      attribute :options, Coradoc::Reference::Edge::Options

      class << self
        # Build an Edge with the given kind. Options are coerced to the
        # kind's options class (if any) via the Kind registry — never
        # hand-rolled.
        def build(kind:, address:, source_id: nil, label: nil, options: nil)
          options_class = Kind.options_class_for(kind)
          coerced = coerce_options(options, options_class)
          new(
            kind: kind.to_s,
            address: address,
            source_id: source_id,
            label: label,
            options: coerced
          )
        end

        def register_kind(name, options_class: nil)
          Kind.register(name, options_class: options_class)
        end

        def kinds
          Kind.names
        end

        private

        def coerce_options(value, options_class)
          return options_class.new if value.nil?
          return value if value.is_a?(options_class)
          return options_class.new if options_class.nil?

          options_class.new(value)
        end
      end

      def ==(other)
        return false unless other.is_a?(Edge)

        %i[kind address source_id label options].all? do |a|
          public_send(a) == other.public_send(a)
        end
      end
      alias eql? ==

      def hash
        [kind, address, source_id, label, options].hash
      end
    end
  end
end
