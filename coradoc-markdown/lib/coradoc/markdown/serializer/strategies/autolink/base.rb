# frozen_string_literal: true

module Coradoc
  module Markdown
    class Serializer
      module Strategies
        module Autolink
          # A link whose text equals its URL is a bare URL. Each strategy
          # decides how to format it. `applies?` is checked first; if no
          # strategy applies, the caller falls back to standard link syntax.
          #
          # Adding a new autolink form = adding one file + one entry in
          # Registry::MODES. No call-site changes — Open/Closed.
          class Base
            class << self
              def applies?(_url, _text, _ctx)
                raise NotImplementedError
              end

              def render(_url, _text, _ctx)
                raise NotImplementedError
              end

              def mode_name
                name.split('::').last.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase.to_sym
              end
            end
          end
        end
      end
    end
  end
end
