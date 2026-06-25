# frozen_string_literal: true

module Coradoc
  module Mirror
    # Handler modules for transforming CoreModel types to Mirror nodes.
    #
    # Each handler is a module/class that responds to +call(element, context:)+,
    # where +element+ is a CoreModel instance and +context+ is the
    # CoreModelToMirror transformer providing shared helpers.
    #
    # New handlers are added by creating a new module file and registering
    # it in +Coradoc::Mirror.default_registry+ — no existing code changes (OCP).
    module Handlers
      autoload :Structural, "#{__dir__}/handlers/structural"
      autoload :Paragraph, "#{__dir__}/handlers/paragraph"
      autoload :CodeBlock, "#{__dir__}/handlers/code_block"
      autoload :Blockquote, "#{__dir__}/handlers/blockquote"
      autoload :Example, "#{__dir__}/handlers/example"
      autoload :Sidebar, "#{__dir__}/handlers/sidebar"
      autoload :OpenBlock, "#{__dir__}/handlers/open_block"
      autoload :Verse, "#{__dir__}/handlers/verse"
      autoload :Comment, "#{__dir__}/handlers/comment"
      autoload :HorizontalRule, "#{__dir__}/handlers/horizontal_rule"
      autoload :Reviewer, "#{__dir__}/handlers/reviewer"
      autoload :Admonition, "#{__dir__}/handlers/admonition"
      autoload :List, "#{__dir__}/handlers/list"
      autoload :DefinitionList, "#{__dir__}/handlers/definition_list"
      autoload :Table, "#{__dir__}/handlers/table"
      autoload :Image, "#{__dir__}/handlers/image"
      autoload :Inline, "#{__dir__}/handlers/inline"
      autoload :Bibliography, "#{__dir__}/handlers/bibliography"
      autoload :Footnote, "#{__dir__}/handlers/footnote"
      autoload :Toc, "#{__dir__}/handlers/toc"
      autoload :Frontmatter, "#{__dir__}/handlers/frontmatter"
      autoload :GenericBlock, "#{__dir__}/handlers/generic_block"
      autoload :Include, "#{__dir__}/handlers/include"
    end
  end
end
