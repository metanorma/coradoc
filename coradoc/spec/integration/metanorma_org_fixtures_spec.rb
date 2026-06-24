# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'metanorma.org _posts fixtures', type: :integration do
  fixtures_dir = File.expand_path('../fixtures/metanorma_org_posts', __dir__)
  fixtures = Dir.glob(File.join(fixtures_dir, '*.adoc'))

  fixtures.each do |path|
    slug = File.basename(path, '.adoc')

    describe slug do
      let(:adoc_text) { File.read(path) }
      let(:core) { Coradoc::AsciiDoc.parse_to_core(adoc_text) }
      let(:frontmatter) do
        core.children.find { |c| c.is_a?(Coradoc::CoreModel::FrontmatterBlock) }
      end

      it 'parses into a FrontmatterBlock' do
        skip 'fixture has no frontmatter' unless adoc_text.start_with?("---\n")
        expect(frontmatter).to be_a(Coradoc::CoreModel::FrontmatterBlock)
        expect(frontmatter).not_to be_empty
      end

      it 'preserves the title field' do
        skip 'fixture has no frontmatter' unless adoc_text.start_with?("---\n")
        expect(frontmatter.data['title']).to be_a(String)
        expect(frontmatter.data['title']).not_to be_empty
      end

      it 'preserves author/authors field as Hash/Array' do
        skip 'fixture has no frontmatter' unless adoc_text.start_with?("---\n")
        author_value = frontmatter.data['author'] || frontmatter.data['authors']
        skip 'no author field' unless author_value

        case author_value
        when Hash
          expect(author_value['name']).to be_a(String)
        when Array
          expect(author_value).not_to be_empty
          expect(author_value.first).to be_a(Hash)
        else
          raise "unexpected author type: #{author_value.class}"
        end
      end

      it 'preserves the date field' do
        skip 'fixture has no frontmatter' unless adoc_text.start_with?("---\n")
        date_value = frontmatter.data['date']
        skip 'no date field' unless date_value
        expect([Date, Time, DateTime]).to include(date_value.class)
      end

      it 'round-trips through CoreModel → Markdown → CoreModel' do
        skip 'fixture has no frontmatter' unless adoc_text.start_with?("---\n")

        md_doc = Coradoc::Markdown.from_core_model(core)
        md_out = Coradoc::Markdown.serialize(md_doc)
        expect(md_out).to start_with("---\n")
        expect(md_out).to include(frontmatter.data['title'])

        md_core = Coradoc::Markdown.to_core_model(md_doc)
        fm2 = md_core.children.find { |c| c.is_a?(Coradoc::CoreModel::FrontmatterBlock) }
        expect(fm2).to be_a(Coradoc::CoreModel::FrontmatterBlock)
        expect(fm2.data['title']).to eq(frontmatter.data['title'])
        expect(fm2.data['date']).to eq(frontmatter.data['date'])

        if (original_tags = frontmatter.data['tags'] || frontmatter.data['categories'])
          expect(fm2.data['tags'] || fm2.data['categories']).to eq(original_tags)
        end
      end

      it 'round-trips through CoreModel → Mirror → CoreModel', if: defined?(Coradoc::Mirror) do
        skip 'fixture has no frontmatter' unless adoc_text.start_with?("---\n")

        mirror_doc = Coradoc::Mirror.transform(core)
        parsed = JSON.parse(JSON.generate(mirror_doc.to_hash))
        rebuilt = Coradoc::Mirror::MirrorToCoreModel.new.call(
          Coradoc::Mirror.from_hash(parsed)
        )

        fm2 = rebuilt.children.find { |c| c.is_a?(Coradoc::CoreModel::FrontmatterBlock) }
        expect(fm2).to be_a(Coradoc::CoreModel::FrontmatterBlock)
        expect(fm2.data['title']).to eq(frontmatter.data['title'])
        # Typed tree preserves Date/Time semantics as Date/DateTime; the
        # exact class may shift (Time → DateTime) but the instant matches.
        original_date = frontmatter.data['date']
        rebuilt_date = fm2.data['date']
        if original_date.is_a?(Time) || original_date.is_a?(DateTime) ||
           original_date.is_a?(Date)
          expect(rebuilt_date.iso8601).to eq(original_date.iso8601)
        else
          expect(rebuilt_date).to eq(original_date)
        end
      end
    end
  end
end
