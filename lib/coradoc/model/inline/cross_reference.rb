# frozen_string_literal: true

module Coradoc
  module Model
    module Inline
      class CrossReference < Base
        attribute :href, :string
        attribute :args, :string, collection: true

        asciidoc do
          map_attribute "href", to: :href
          map_attribute "args", to: :args
        end

        def to_asciidoc
          if args&.length&.> 0
            _args = args.reject(&:empty?).map { |a|
              Coradoc::Generator.gen_adoc(a)
            }.join(",")

            if _args.empty?
              return "<<#{href}>>"
            else
              return "<<#{href},#{_args}>>"
            end
          end
          "<<#{href}>>"
        end
      end
    end
  end
end
