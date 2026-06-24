# frozen_string_literal: true

require 'json'
require 'yaml'

module Coradoc
  module Mirror
    # Output processors that integrate with the Coradoc::Output pipeline.
    #
    # Enables:
    #   Coradoc.serialize(doc, to: :mirror_json)
    #   Coradoc.serialize(doc, to: :mirror_yaml)
    module Output
      # JSON output processor for the Coradoc::Output pipeline.
      class MirrorJson
        class << self
          def processor_id
            :mirror_json
          end

          def processor_match?(filename)
            filename.downcase.end_with?('.mirror.json')
          end

          def processor_execute(input, options = {})
            pretty = options[:pretty] != false
            input.each_with_object({}) do |(filename, document), result|
              node = Coradoc::Mirror.transform(document)
              result[filename] = pretty ? JSON.pretty_generate(node.to_hash) : JSON.generate(node.to_hash)
            end
          end
        end
      end

      # YAML output processor for the Coradoc::Output pipeline.
      class MirrorYaml
        class << self
          def processor_id
            :mirror_yaml
          end

          def processor_match?(filename)
            filename.downcase.end_with?('.mirror.yaml', '.mirror.yml')
          end

          def processor_execute(input, _options = {})
            input.each_with_object({}) do |(filename, document), result|
              node = Coradoc::Mirror.transform(document)
              result[filename] = YAML.dump(node.to_hash)
            end
          end
        end
      end
    end
  end
end

# Register with the Coradoc::Output pipeline if available.
if defined?(Coradoc::Output)
  Coradoc::Output.define(Coradoc::Mirror::Output::MirrorJson)
  Coradoc::Output.define(Coradoc::Mirror::Output::MirrorYaml)
end
