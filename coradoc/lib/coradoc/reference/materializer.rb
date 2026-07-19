# frozen_string_literal: true

module Coradoc
  module Reference
    # Render an Edge per (kind, presentation, format). Registry-based:
    # adding a new output format or citation style is registering a
    # new materializer, not editing switch statements.
    module Materializer
      autoload :Base, "#{__dir__}/materializer/base"
      autoload :Registry, "#{__dir__}/materializer/registry"
      autoload :Passthrough, "#{__dir__}/materializer/passthrough"
    end
  end
end
