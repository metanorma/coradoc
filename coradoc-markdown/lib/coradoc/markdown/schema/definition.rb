# frozen_string_literal: true

module Coradoc
  module Markdown
    module Schema
      # Reads schema files and builds lutaml-model schema definitions
      # (Lutaml::Model::Schema::Definitions::Model) from them.
      class Definition
        SCALARS = %w[string integer boolean float date].freeze

        # `false` is a legitimate default but lutaml-model's renderer only
        # emits `default:` for truthy values; this renders as the literal.
        FalseDefault = Struct.new(:source) do
          def inspect = source
        end

        # @param files [Array<String>] schema file paths
        # @return [Array<Definition>] one per declared class, in file order
        def self.read(files)
          files.flat_map do |file|
            YAML.safe_load_file(file).fetch('classes').map do |name, spec|
              new(name, spec, source: File.basename(file))
            end
          end
        end

        attr_reader :name, :source

        def initialize(name, spec, source: nil)
          @name = name
          @spec = spec
          @source = source
        end

        # @return [Array<String>] names of Behaviors modules to prepend
        def behaviors
          Array(@spec['behaviors'])
        end

        # @param namespace [String] namespace generated sibling classes live in
        # @return [Lutaml::Model::Schema::Definitions::Model]
        def to_model(namespace:)
          defs = Lutaml::Model::Schema::Definitions
          members = @spec.fetch('attributes').map do |attr_name, opts|
            attribute(attr_name, opts, namespace)
          end
          defs::Model.new(class_name: name,
                          xml_root: defs::XmlRoot.new(kind: :none),
                          members: members,
                          parent_class: "Coradoc::Markdown::#{@spec.fetch('parent')}")
        end

        private

        def attribute(attr_name, opts, namespace)
          Lutaml::Model::Schema::Definitions::Attribute.new(
            name: attr_name.to_sym, type: type_ref(opts.fetch('type'), namespace),
            xml_name: attr_name, kind: :attribute,
            collection: opts['collection'] == true,
            default: default_for(opts)
          )
        end

        def default_for(opts)
          return unless opts.key?('default')

          opts['default'] == false ? FalseDefault.new('false') : opts['default']
        end

        def type_ref(type, namespace)
          defs = Lutaml::Model::Schema::Definitions
          return defs::TypeRef.new(kind: :symbol, value: type) if SCALARS.include?(type)

          # Base is hand-written and shared; every other model is a sibling.
          scope = type == 'Base' ? 'Coradoc::Markdown' : namespace
          defs::TypeRef.new(kind: :class_ref, value: "#{scope}::#{type}")
        end
      end
    end
  end
end
