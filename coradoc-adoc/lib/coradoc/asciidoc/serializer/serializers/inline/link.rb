# frozen_string_literal: true

require 'uri'

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Inline
          class Link < Base
            def to_adoc(model, _options = {})
              link = model.path.dup
              link = "link:#{link}" unless model.path&.match?(URI::DEFAULT_PARSER.make_regexp)

              name_empty = model.name.nil? || model.name.empty?
              title_empty = model.title.nil? || model.title.empty?
              valid_empty_name_link = link.start_with?(%r{https?://})

              link << if name_empty && !title_empty
                        "[#{model.title}]"
                      elsif !name_empty
                        "[#{model.name}]"
                      elsif valid_empty_name_link && !model.right_constrain
                        ''
                      else
                        '[]'
                      end
              link
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Coradoc::AsciiDoc::Model::Inline::Link, Inline::Link)
      end
    end
  end
end
