# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module Inline
        class Base < Coradoc::AsciiDoc::Model::Base
          def inline?
            true
          end
        end
      end
    end
  end
end
