# frozen_string_literal: true

module Coradoc
  module Html
    # Materializers rendering resolved reference Edges into
    # HTML-shaped CoreModel nodes. They live in the format gem (not
    # coradoc core) so format knowledge stays at the spoke of the
    # hub-and-spoke architecture; registration is a load-time side
    # effect via the Materializer registry's global extension point.
    module ReferenceMaterializers
      autoload :Navigation, 'coradoc/html/reference_materializers/navigation'
      autoload :Link, 'coradoc/html/reference_materializers/link'
    end
  end
end

Coradoc::Reference::Materializer::Registry.register_global(
  Coradoc::Html::ReferenceMaterializers::Navigation
)
Coradoc::Reference::Materializer::Registry.register_global(
  Coradoc::Html::ReferenceMaterializers::Link
)
