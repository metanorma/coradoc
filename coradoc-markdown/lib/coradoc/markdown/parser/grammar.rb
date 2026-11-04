# frozen_string_literal: true

require 'parsanol'
require 'parsanol/parg'

module Coradoc
  module Markdown
    module Parser
      # The compiled PARG artifact for the block grammar
      # (grammar/coradoc-markdown.parg is the single source of truth).
      # The Ruby-DSL BlockParser stays as the parity reference.
      module Grammar
        # Load-time side effect (sanctioned require_relative exception):
        # the artifact resolves its custom atoms by constant name.
        require_relative 'grammar_runtime'

        GRAMMAR_DIR = File.expand_path('../../../../grammar', __dir__)
        SOURCE_PATH = File.join(GRAMMAR_DIR, 'coradoc-markdown.parg')
        ARTIFACT_PATH = File.join(GRAMMAR_DIR, 'coradoc-markdown.artifact.json')
        BINDINGS_PATH = File.join(GRAMMAR_DIR, 'coradoc-markdown.bindings.yml')

        class << self
          def artifact
            @artifact ||= Parsanol::PARG::Artifact.load(ARTIFACT_PATH)
          end

          # Parse block markdown to the same tree shape the DSL grammar
          # produces (slices intact).
          def parse(input, **)
            artifact.parse('document', input, **)
          end

          # A named rule's atom, for the custom atoms that apply
          # grammar rules from inside Ruby-tier matching.
          def atom(rule)
            (@atoms ||= {})[rule] ||= artifact.send(:compiler).atom_for(rule)
          end

          # The rule -> model table embedded in the artifact (nil if none).
          def model_bindings
            artifact.envelope['model_bindings']
          end

          # Compile the .parg to its artifact JSON text, embedding the
          # bindings sidecar (needs a parsanol with ModelBindings).
          def compile_source
            document = Parsanol::PARG::Parser.new(File.read(SOURCE_PATH)).parse
            envelope = Parsanol::PARG::Compiler.compile(document).envelope
            envelope = Parsanol::PARG::ModelBindings.embed(envelope, Parsanol::PARG::ModelBindings.load(BINDINGS_PATH))
            Parsanol::PARG::Compiler.seal_json(envelope)
          end
        end
      end
    end
  end
end
