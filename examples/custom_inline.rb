# frozen_string_literal: true

# Custom inline element examples for Coradoc
#
# This file demonstrates how to create and use custom inline elements.

require_relative '../lib/coradoc'

# Example 1: Create a custom highlight inline element
puts '=== Example 1: Create a custom highlight inline element ==='

# Define the custom inline class
module Coradoc
  module Model
    module Inline
      class Highlight < Base
        attribute :text, :string
        attribute :color, :string, default: -> { 'yellow' }
      end
    end
  end
end

# Create a custom serializer
module Coradoc
  module Output
    module Adoc
      module Serializers
        class HighlightSerializer
          def initialize(model)
            @model = model
          end

          def serialize_to_adoc
            "##{@model.text}#"
          end
        end
      end
    end
  end
end

# Register the serializer
Coradoc::Output::Adoc::ElementRegistry.register(
  Coradoc::Model::Inline::Highlight,
  Coradoc::Output::Adoc::Serializers::HighlightSerializer
)

# Use the custom inline element
highlight = Coradoc::Model::Inline::Highlight.new
highlight.text = 'important text'

puts 'Custom highlight element:'
puts highlight.to_adoc
puts

# Example 2: Create a custom code inline element
puts '=== Example 2: Create a custom code inline element ==='

module Coradoc
  module Model
    module Inline
      class Code < Base
        attribute :code, :string
        attribute :language, :string, default: -> { 'text' }
      end
    end
  end
end

module Coradoc
  module Output
    module Adoc
      module Serializers
        class CodeSerializer
          def initialize(model)
            @model = model
          end

          def serialize_to_adoc
            "`#{@model.code}`"
          end
        end
      end
    end
  end
end

Coradoc::Output::Adoc::ElementRegistry.register(
  Coradoc::Model::Inline::Code,
  Coradoc::Output::Adoc::Serializers::CodeSerializer
)

code = Coradoc::Model::Inline::Code.new
code.code = "puts 'Hello'"

puts 'Custom code element:'
puts code.to_adoc
puts

# Example 3: Create a custom mark inline element
puts '=== Example 3: Create a custom mark inline element ==='

module Coradoc
  module Model
    module Inline
      class Mark < Base
        attribute :text, :string
      end
    end
  end
end

module Coradoc
  module Output
    module Adoc
      module Serializers
        class MarkSerializer
          def initialize(model)
            @model = model
          end

          def serialize_to_adoc
            "##{@model.text}#"
          end
        end
      end
    end
  end
end

Coradoc::Output::Adoc::ElementRegistry.register(
  Coradoc::Model::Inline::Mark,
  Coradoc::Output::Adoc::Serializers::MarkSerializer
)

mark = Coradoc::Model::Inline::Mark.new
mark.text = 'marked text'

puts 'Custom mark element:'
puts mark.to_adoc
puts

# Example 4: Create a custom keycap inline element
puts '=== Example 4: Create a custom keycap inline element ==='

module Coradoc
  module Model
    module Inline
      class Keycap < Base
        attribute :key, :string
      end
    end
  end
end

module Coradoc
  module Output
    module Adoc
      module Serializers
        class KeycapSerializer
          def initialize(model)
            @model = model
          end

          def serialize_to_adoc
            "kbd:[#{@model.key}]"
          end
        end
      end
    end
  end
end

Coradoc::Output::Adoc::ElementRegistry.register(
  Coradoc::Model::Inline::Keycap,
  Coradoc::Output::Adoc::Serializers::KeycapSerializer
)

keycap = Coradoc::Model::Inline::Keycap.new
keycap.key = 'Ctrl'

puts 'Custom keycap element:'
puts keycap.to_adoc
puts

# Example 5: Use custom inline elements in a paragraph
puts '=== Example 5: Use custom inline elements in a paragraph ==='

paragraph = Coradoc::Model::Paragraph.new
paragraph.content = [
  Coradoc::Model::TextElement.new('Press '),
  Coradoc::Model::Inline::Keycap.new(key: 'Ctrl'),
  Coradoc::Model::TextElement.new(' + '),
  Coradoc::Model::Inline::Keycap.new(key: 'C'),
  Coradoc::Model::TextElement.new(' to copy, and '),
  Coradoc::Model::Inline::Highlight.new(text: 'this is highlighted'),
  Coradoc::Model::TextElement.new(' text.')
]

puts 'Paragraph with custom inline elements:'
puts paragraph.to_adoc
puts

# Example 6: Mix custom and built-in inline elements
puts '=== Example 6: Mix custom and built-in inline elements ==='

paragraph = Coradoc::Model::Paragraph.new
paragraph.content = [
  Coradoc::Model::TextElement.new('This has '),
  Coradoc::Model::Inline::Bold.new(content: 'built-in bold'),
  Coradoc::Model::TextElement.new(' and '),
  Coradoc::Model::Inline::Highlight.new(text: 'custom highlight'),
  Coradoc::Model::TextElement.new(' together.')
]

puts 'Mixed inline elements:'
puts paragraph.to_adoc
puts

# Example 7: Create a custom icon inline element
puts '=== Example 7: Create a custom icon inline element ==='

module Coradoc
  module Model
    module Inline
      class Icon < Base
        attribute :icon_name, :string
        attribute :size, :string, default: -> { '1x' }
      end
    end
  end
end

module Coradoc
  module Output
    module Adoc
      module Serializers
        class IconSerializer
          def initialize(model)
            @model = model
          end

          def serialize_to_adoc
            "icon:#{@model.icon_name}[size=#{@model.size}]"
          end
        end
      end
    end
  end
end

Coradoc::Output::Adoc::ElementRegistry.register(
  Coradoc::Model::Inline::Icon,
  Coradoc::Output::Adoc::Serializers::IconSerializer
)

icon = Coradoc::Model::Inline::Icon.new
icon.icon_name = 'fire'
icon.size = '2x'

puts 'Custom icon element:'
puts icon.to_adoc
puts

# Example 8: Custom inline elements in document sections
puts '=== Example 8: Custom inline elements in document sections ==='

section = Coradoc::Model::Section.new
section.title = Coradoc::Model::Title.new
section.title.content = ['Keyboard Shortcuts']

paragraph = Coradoc::Model::Paragraph.new
paragraph.content = [
  Coradoc::Model::TextElement.new('Use '),
  Coradoc::Model::Inline::Keycap.new(key: 'Ctrl'),
  Coradoc::Model::TextElement.new(' + '),
  Coradoc::Model::Inline::Keycap.new(key: 'S'),
  Coradoc::Model::TextElement.new(' to save your work.')
]
section.blocks = [paragraph]

puts 'Section with custom inline elements:'
puts section.to_adoc
puts

# Example 9: Create a menu inline element
puts '=== Example 9: Create a menu inline element ==='

module Coradoc
  module Model
    module Inline
      class Menu < Base
        attribute :menu_path, :string
      end
    end
  end
end

module Coradoc
  module Output
    module Adoc
      module Serializers
        class MenuSerializer
          def initialize(model)
            @model = model
          end

          def serialize_to_adoc
            "menu:#{@model.menu_path}[]"
          end
        end
      end
    end
  end
end

Coradoc::Output::Adoc::ElementRegistry.register(
  Coradoc::Model::Inline::Menu,
  Coradoc::Output::Adoc::Serializers::MenuSerializer
)

menu = Coradoc::Model::Inline::Menu.new
menu.menu_path = 'File[Save]'

puts 'Custom menu element:'
puts menu.to_adoc
puts

puts '=== All examples completed ==='
