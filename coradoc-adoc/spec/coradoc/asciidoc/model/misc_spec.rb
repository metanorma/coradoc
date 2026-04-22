# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::AsciiDoc::Model::CommentBlock do
  describe '.new' do
    it 'creates a comment block' do
      comment = described_class.new(text: 'This is a comment')

      expect(comment.text).to eq('This is a comment')
    end
  end

  describe 'inheritance' do
    it 'inherits from Base' do
      comment = described_class.new

      expect(comment).to be_a(Coradoc::AsciiDoc::Model::Base)
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::CommentLine do
  describe '.new' do
    it 'creates a comment line' do
      comment = described_class.new(text: 'Inline comment')

      expect(comment.text).to eq('Inline comment')
    end
  end

  describe 'inheritance' do
    it 'inherits from Base' do
      comment = described_class.new

      expect(comment).to be_a(Coradoc::AsciiDoc::Model::Base)
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::LineBreak do
  describe '.new' do
    it 'creates a line break' do
      br = described_class.new

      expect(br).to be_a(Coradoc::AsciiDoc::Model::Base)
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::Include do
  describe '.new' do
    it 'creates an include directive' do
      inc = described_class.new(
        path: 'chapter1.adoc'
      )

      expect(inc.path).to eq('chapter1.adoc')
    end
  end

  describe 'inheritance' do
    it 'inherits from Base' do
      inc = described_class.new

      expect(inc).to be_a(Coradoc::AsciiDoc::Model::Base)
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::Highlight do
  describe '.new' do
    it 'creates a highlight element' do
      highlight = described_class.new(content: 'highlighted')

      expect(highlight.content).to eq('highlighted')
    end
  end

  describe 'inheritance' do
    it 'inherits from TextElement' do
      highlight = described_class.new

      expect(highlight).to be_a(Coradoc::AsciiDoc::Model::TextElement)
    end

    it 'inherits from Base' do
      highlight = described_class.new

      expect(highlight).to be_a(Coradoc::AsciiDoc::Model::Base)
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::Tag do
  describe '.new' do
    it 'creates a tag' do
      tag = described_class.new(
        id: 'tag-1'
      )

      expect(tag.id).to eq('tag-1')
    end
  end

  describe 'inheritance' do
    it 'inherits from Base' do
      tag = described_class.new

      expect(tag).to be_a(Coradoc::AsciiDoc::Model::Base)
    end
  end
end

RSpec.describe Coradoc::AsciiDoc::Model::ReviewerNote do
  describe '.new' do
    it 'creates a reviewer note' do
      note = described_class.new(
        content: 'Review this section'
      )

      expect(note.content).to eq('Review this section')
    end
  end

  describe 'inheritance' do
    it 'inherits from Base' do
      note = described_class.new

      expect(note).to be_a(Coradoc::AsciiDoc::Model::Base)
    end
  end
end
