# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

module Coradoc
  module Markdown
    module Schema
      # Compiles Definitions into classes with lutaml-model's schema
      # pipeline and applies the hand-written behavior modules.
      #
      # lutaml-model's ClassLoader writes class files under
      # <dir>/<nested/namespace>/ but its registry requires them from
      # <dir>/<last_segment>/, so a nested namespace cannot load; this
      # subclass mirrors the files to where the registry looks for them.
      class Loader
        DEFAULT_NAMESPACE = 'Coradoc::Markdown::Generated'

        # ClassLoader with the nested-namespace path corrected.
        class NestedClassLoader < Lutaml::Model::Schema::ClassLoader
          def load
            Dir.mktmpdir do |dir|
              Lutaml::Model::Schema::FileWriter.write(@output, dir, registry_generator: @registry_generator)
              mirror_class_dir(dir)
              require File.join(dir, "#{registry_basename}_registry")
              call_register_all
            end
          end

          private

          def mirror_class_dir(dir)
            segments = @output.module_namespace.downcase.split('::')
            FileUtils.cp_r(File.join(dir, *segments), File.join(dir, segments.last)) if segments.size > 1
          end
        end

        def initialize(definitions, namespace: DEFAULT_NAMESPACE)
          @definitions = definitions
          @namespace = namespace
        end

        # @return [Array<Class>] generated classes, behaviors applied
        def load
          entries = @definitions.map do |definition|
            Lutaml::Model::Schema::CompiledOutput::Entry.new(
              definition.name, definition.to_model(namespace: @namespace), :model
            )
          end
          output = Lutaml::Model::Schema::CompiledOutput.new(entries: entries, module_namespace: @namespace)
          NestedClassLoader.load(output)
          apply_behaviors
        end

        private

        def apply_behaviors
          host = Object.const_get(@namespace)
          @definitions.map do |definition|
            klass = host.const_get(definition.name)
            definition.behaviors.each { |name| klass.prepend(Behaviors.const_get(name)) }
            klass
          end
        end
      end
    end
  end
end
