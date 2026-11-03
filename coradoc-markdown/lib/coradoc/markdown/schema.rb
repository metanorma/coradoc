# frozen_string_literal: true

require 'yaml'

module Coradoc
  module Markdown
    # Declarative schemas (coradoc-markdown/schemas/*.yml) for the Markdown
    # model set, and the machinery that turns them into lutaml-model classes
    # through lutaml-model's schema pipeline.
    #
    #   Schema.load_generated(namespace: 'Coradoc::Markdown::Generated')
    #
    # Generated classes inherit from the hand-written Coradoc::Markdown::Base
    # and get their hand-written behavior from Coradoc::Markdown::Behaviors.
    module Schema
      SCHEMA_DIR = File.expand_path('../../../schemas', __dir__)

      autoload :Definition, 'coradoc/markdown/schema/definition'
      autoload :Loader, 'coradoc/markdown/schema/loader'
      autoload :Parity, 'coradoc/markdown/schema/parity'

      class << self
        # @return [Array<String>] paths of all schema files
        def files
          Dir[File.join(SCHEMA_DIR, '*.yml')]
        end

        # Replace the hand-written model classes with generated ones in
        # Coradoc::Markdown itself (behind CORADOC_MARKDOWN_GENERATED=1).
        def install!
          load_generated(namespace: 'Coradoc::Markdown')
        end

        # A schema-generated class by short name, in the default
        # namespace. The schemas compile once per process.
        #
        # @param name [String] e.g. 'HorizontalRule'
        def generated_class(name)
          @generated ||= load_generated.to_h { |klass| [klass.name.split('::').last, klass] }
          @generated.fetch(name)
        end

        # Compile the schemas and load the resulting classes.
        #
        # @param namespace [String] module that hosts the generated classes
        # @return [Array<Class>] the generated classes
        def load_generated(namespace: Loader::DEFAULT_NAMESPACE)
          Loader.new(Definition.read(files), namespace: namespace).load
        end
      end
    end
  end
end
