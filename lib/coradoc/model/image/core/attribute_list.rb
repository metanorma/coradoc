# frozen_string_literal: true

module Coradoc
  module Model
    module Image
      class Core < Coradoc::Model::Base
        class AttributeList < Coradoc::Model::AttributeList

          extend AttributeList::Matchers

          def named_validators
            super.merge({
              id: String,
              alt: String,
              fallback: String,
              title: String,
              width: Integer,
              height: Integer,
              link: String, # change to that URI regexp
              window: String,
              scale: Integer,
              scaledwidth: /\A[0-9]{1,2}%\z/,
              pdfwidth: /\A[0-9]+vw\z/,
              role: many(/.*/, "left", "right", "th", "thumb", "related", "rel"),
              opts: many("nofollow", "noopener", "inline", "interactive"),
            })
          end
        end
      end
    end
  end
end
