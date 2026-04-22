# frozen_string_literal: true

module Coradoc
  module Html
    module Theme
      # Autoload Theme components
      autoload :Base, 'coradoc/html/theme/base'
      autoload :Registry, 'coradoc/html/theme/registry'
      autoload :ClassicRenderer, 'coradoc/html/theme/classic_renderer'
      autoload :ModernRenderer, 'coradoc/html/theme/modern_renderer'
    end
  end
end
