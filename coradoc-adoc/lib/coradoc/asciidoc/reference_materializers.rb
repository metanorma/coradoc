# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    # Materializers rendering resolved reference Edges into
    # AsciiDoc-shaped CoreModel nodes. They live in the format gem
    # (not coradoc core) so format knowledge stays at the spoke of the
    # hub-and-spoke architecture; registration is a load-time side
    # effect via the Materializer registry's global extension point.
    module ReferenceMaterializers
      autoload :Navigation, "#{__dir__}/reference_materializers/navigation"
    end
  end
end

Coradoc::Reference::Materializer::Registry.register_global(
  Coradoc::AsciiDoc::ReferenceMaterializers::Navigation
)
