# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Model::Inline::Anchor do
  describe '.new' do
    it 'creates an anchor with id' do
      anchor = described_class.new(id: 'section-1')

      expect(anchor.id).to eq('section-1')
    end
  end

  describe 'inheritance' do
    it 'inherits from Inline::Base' do
      anchor = described_class.new

      expect(anchor).to be_a(Coradoc::AsciiDoc::Model::Inline::Base)
    end

    it 'inherits from Base' do
      anchor = described_class.new

      expect(anchor).to be_a(Coradoc::AsciiDoc::Model::Base)
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::Inline::AttributeReference do
  describe '.new' do
    it 'creates an attribute reference' do
      attr_ref = described_class.new(name: 'author')

      expect(attr_ref.name).to eq('author')
    end
  end

  describe 'inheritance' do
    it 'inherits from Inline::Base' do
      attr_ref = described_class.new

      expect(attr_ref).to be_a(Coradoc::AsciiDoc::Model::Inline::Base)
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::Inline::Highlight do
  describe '.new' do
    it 'creates highlight text' do
      highlight = described_class.new(content: 'highlighted')

      expect(highlight.content).to eq('highlighted')
    end
  end

  describe 'inheritance' do
    it 'inherits from Inline::Base' do
      highlight = described_class.new

      expect(highlight).to be_a(Coradoc::AsciiDoc::Model::Inline::Base)
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::Inline::Quotation do
  describe '.new' do
    it 'creates quoted text' do
      quote = described_class.new(content: 'quoted text')

      expect(quote.content).to eq('quoted text')
    end
  end

  describe 'inheritance' do
    it 'inherits from Inline::Base' do
      quote = described_class.new

      expect(quote).to be_a(Coradoc::AsciiDoc::Model::Inline::Base)
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::Inline::Span do
  describe '.new' do
    it 'creates a span with text' do
      span = described_class.new(text: 'span text')

      expect(span.text).to eq('span text')
    end

    it 'creates a span with role' do
      span = described_class.new(role: 'highlight')

      expect(span.role).to eq('highlight')
    end
  end

  describe 'inheritance' do
    it 'inherits from Inline::Base' do
      span = described_class.new

      expect(span).to be_a(Coradoc::AsciiDoc::Model::Inline::Base)
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::Inline::Strikethrough do
  describe '.new' do
    it 'creates strikethrough text' do
      strike = described_class.new(content: 'deleted')

      expect(strike.content).to eq('deleted')
    end
  end

  describe 'inheritance' do
    it 'inherits from Inline::Base' do
      strike = described_class.new

      expect(strike).to be_a(Coradoc::AsciiDoc::Model::Inline::Base)
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::Inline::Subscript do
  describe '.new' do
    it 'creates subscript text' do
      sub = described_class.new(content: '2')

      expect(sub.content).to eq('2')
    end
  end

  describe 'inheritance' do
    it 'inherits from Inline::Base' do
      sub = described_class.new

      expect(sub).to be_a(Coradoc::AsciiDoc::Model::Inline::Base)
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::Inline::Superscript do
  describe '.new' do
    it 'creates superscript text' do
      sup = described_class.new(content: '2')

      expect(sup.content).to eq('2')
    end
  end

  describe 'inheritance' do
    it 'inherits from Inline::Base' do
      sup = described_class.new

      expect(sup).to be_a(Coradoc::AsciiDoc::Model::Inline::Base)
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::Inline::Underline do
  describe '.new' do
    it 'creates underlined text' do
      underline = described_class.new(text: 'underlined')

      expect(underline.text).to eq('underlined')
    end
  end

  describe 'inheritance' do
    it 'inherits from Inline::Base' do
      underline = described_class.new

      expect(underline).to be_a(Coradoc::AsciiDoc::Model::Inline::Base)
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::Inline::Small do
  describe '.new' do
    it 'creates small text' do
      small = described_class.new(text: 'fine print')

      expect(small.text).to eq('fine print')
    end
  end

  describe 'inheritance' do
    it 'inherits from Inline::Base' do
      small = described_class.new

      expect(small).to be_a(Coradoc::AsciiDoc::Model::Inline::Base)
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::Inline::HardLineBreak do
  describe '.new' do
    it 'creates a hard line break' do
      br = described_class.new

      expect(br).to be_a(Coradoc::AsciiDoc::Model::Inline::Base)
    end
  end

  describe 'inheritance' do
    it 'inherits from Inline::Base' do
      br = described_class.new

      expect(br).to be_a(Coradoc::AsciiDoc::Model::Inline::Base)
    end
  end
end
