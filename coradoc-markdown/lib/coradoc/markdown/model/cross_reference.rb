# frozen_string_literal: true

module Coradoc
  module Markdown
    class CrossReference < Base
      attribute :text, :string
      attribute :target, :string
    end
  end
end
