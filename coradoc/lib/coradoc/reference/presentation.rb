# frozen_string_literal: true

module Coradoc
  module Reference
    # Model-View boundary. Same Content graph → N Presentations. A
    # Presentation defines slicing, page boundaries, ordering, and
    # hierarchy — never the rendering (that's the Materializer's job).
    module Presentation
      autoload :Base, "#{__dir__}/presentation/base"
      autoload :Page, "#{__dir__}/presentation/page"
      autoload :SingleDocument, "#{__dir__}/presentation/single_document"
      autoload :SplitPages, "#{__dir__}/presentation/split_pages"
      autoload :CustomHierarchy, "#{__dir__}/presentation/custom_hierarchy"
    end
  end
end
