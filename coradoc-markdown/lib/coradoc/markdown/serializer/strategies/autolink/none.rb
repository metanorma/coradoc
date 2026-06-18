# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Markdown
    class Serializer
      module Strategies
        module Autolink
          # No autolink form — emit standard [text](url). The default
          # when `autolinks: false` or when text differs from url.
          class None < Base
            class << self
              def applies?(_url, _text, _ctx)
                false
              end

              def render(_url, _text, _ctx)
                raise NotImplementedError, 'None strategy never renders'
              end
            end
          end
        end
      end
    end
  end
end
