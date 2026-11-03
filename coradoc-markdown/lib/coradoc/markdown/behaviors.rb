# frozen_string_literal: true

module Coradoc
  module Markdown
    # Hand-written behavior modules, one per model that needs methods beyond
    # its attributes. Both the hand-written models and the schema-generated
    # classes prepend the same module, so behavior has a single source.
    module Behaviors
      autoload :AttributeList, 'coradoc/markdown/behaviors/attribute_list'
      autoload :Admonition, 'coradoc/markdown/behaviors/admonition'
      autoload :Document, 'coradoc/markdown/behaviors/document'
      autoload :Extension, 'coradoc/markdown/behaviors/extension'
      autoload :HardLineBreak, 'coradoc/markdown/behaviors/hard_line_break'
      autoload :Heading, 'coradoc/markdown/behaviors/heading'
      autoload :Math, 'coradoc/markdown/behaviors/math'
      autoload :Text, 'coradoc/markdown/behaviors/text'
    end
  end
end
