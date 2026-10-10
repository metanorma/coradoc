# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Parser
      autoload :Base, "#{__dir__}/parser/base"
      autoload :Cache, "#{__dir__}/parser/cache"
      autoload :FrontmatterParser, "#{__dir__}/parser/frontmatter_parser"
      autoload :Inline, "#{__dir__}/parser/inline"
      autoload :PositionedString, "#{__dir__}/parser/positioned_string"
      autoload :TreeMaterializer, "#{__dir__}/parser/tree_materializer"
    end
  end
end
