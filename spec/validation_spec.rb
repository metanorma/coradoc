# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coradoc::Validation do
  describe Coradoc::Validation::Error do
    describe '#initialize' do
      it 'creates error with message' do
        error = described_class.new('Test error')
        expect(error.message).to eq('Test error')
        expect(error.path).to be_nil
        expect(error.code).to be_nil
        expect(error.element).to be_nil
      end

      it 'creates error with all attributes' do
        element = double('element')
        error = described_class.new(
          'Test error',
          path: 'section.title',
          code: :required,
          element: element
        )
        expect(error.message).to eq('Test error')
        expect(error.path).to eq('section.title')
        expect(error.code).to eq(:required)
        expect(error.element).to eq(element)
      end
    end

    describe '#to_s' do
      it 'formats error with path' do
        error = described_class.new('Test error', path: 'section.title')
        expect(error.to_s).to eq('section.title: Test error')
      end

      it 'formats error without path' do
        error = described_class.new('Test error')
        expect(error.to_s).to eq('Test error')
      end
    end

    describe '#to_h' do
      it 'converts to hash' do
        error = described_class.new('Test error', path: 'title', code: :required)
        expect(error.to_h).to eq({
                                   message: 'Test error',
                                   path: 'title',
                                   code: :required
                                 })
      end
    end
  end

  describe Coradoc::Validation::Result do
    describe '#initialize' do
      it 'creates empty result' do
        result = described_class.new
        expect(result.errors).to eq([])
        expect(result.warnings).to eq([])
        expect(result).to be_valid
      end

      it 'creates result with errors and warnings' do
        errors = [Coradoc::Validation::Error.new('Error 1')]
        warnings = [Coradoc::Validation::Error.new('Warning 1')]
        result = described_class.new(errors: errors, warnings: warnings)
        expect(result.error_count).to eq(1)
        expect(result.warning_count).to eq(1)
        expect(result).not_to be_valid
      end
    end

    describe '#valid?' do
      it 'returns true when no errors' do
        result = described_class.new
        expect(result).to be_valid
      end

      it 'returns false when errors present' do
        result = described_class.new(errors: [Coradoc::Validation::Error.new('Error')])
        expect(result).not_to be_valid
      end
    end

    describe '#warnings?' do
      it 'returns false when no warnings' do
        result = described_class.new
        expect(result).not_to be_warnings
      end

      it 'returns true when warnings present' do
        result = described_class.new(warnings: [Coradoc::Validation::Error.new('Warning')])
        expect(result).to be_warnings
      end
    end

    describe '#add_error' do
      it 'adds error to result' do
        result = described_class.new
        error = result.add_error('New error', path: 'field', code: :invalid)
        expect(error.message).to eq('New error')
        expect(result.error_count).to eq(1)
      end
    end

    describe '#add_warning' do
      it 'adds warning to result' do
        result = described_class.new
        warning = result.add_warning('New warning', path: 'field', code: :deprecated)
        expect(warning.message).to eq('New warning')
        expect(result.warning_count).to eq(1)
      end
    end

    describe '#merge!' do
      it 'merges another result' do
        result1 = described_class.new(errors: [Coradoc::Validation::Error.new('Error 1')])
        result2 = described_class.new(
          errors: [Coradoc::Validation::Error.new('Error 2')],
          warnings: [Coradoc::Validation::Error.new('Warning 1')]
        )
        result1.merge!(result2)
        expect(result1.error_count).to eq(2)
        expect(result1.warning_count).to eq(1)
      end
    end

    describe '#errors_at' do
      it 'filters errors by path' do
        error1 = Coradoc::Validation::Error.new('Error 1', path: 'title')
        error2 = Coradoc::Validation::Error.new('Error 2', path: 'content')
        error3 = Coradoc::Validation::Error.new('Error 3', path: 'title')
        result = described_class.new(errors: [error1, error2, error3])

        title_errors = result.errors_at('title')
        expect(title_errors).to contain_exactly(error1, error3)
      end
    end

    describe '#to_h' do
      it 'converts to hash' do
        error = Coradoc::Validation::Error.new('Error', path: 'title', code: :required)
        warning = Coradoc::Validation::Error.new('Warning', path: 'content', code: :deprecated)
        result = described_class.new(errors: [error], warnings: [warning])

        hash = result.to_h
        expect(hash[:valid]).to be false
        expect(hash[:error_count]).to eq(1)
        expect(hash[:warning_count]).to eq(1)
        expect(hash[:errors]).to be_an(Array)
        expect(hash[:warnings]).to be_an(Array)
      end
    end
  end

  describe Coradoc::Validation::Schema do
    describe '.define' do
      it 'creates schema with block' do
        schema = described_class.define do
          required :title, type: String
          optional :author, type: String
        end

        expect(schema.fields[:title][:required]).to be true
        expect(schema.fields[:title][:type]).to eq(String)
        expect(schema.fields[:author][:required]).to be false
      end
    end

    describe '#required' do
      it 'defines required field' do
        schema = described_class.new
        schema.required :title, type: String, min_length: 1

        expect(schema.fields[:title]).to eq({
                                              required: true,
                                              type: String,
                                              min_length: 1
                                            })
      end
    end

    describe '#optional' do
      it 'defines optional field' do
        schema = described_class.new
        schema.optional :subtitle, type: String, max_length: 100

        expect(schema.fields[:subtitle]).to eq({
                                                 required: false,
                                                 type: String,
                                                 max_length: 100
                                               })
      end
    end

    describe '#rule' do
      it 'adds custom validation rule' do
        schema = described_class.new
        schema.rule(:check_title) do |doc|
          doc.title&.start_with?('A') ? [] : ["Title must start with 'A'"]
        end

        expect(schema.rules).to be_an(Array)
        expect(schema.rules.first.name).to eq(:check_title)
      end
    end

    describe '#validate' do
      let(:schema) do
        described_class.define do
          required :title, type: String, min_length: 1
          optional :level, type: Integer
          optional :tags, type: Array, min_count: 1

          rule :check_title do |doc|
            title = doc.respond_to?(:title) ? doc.title : nil
            if title && title.length > 100
              ['Title is too long']
            else
              []
            end
          end
        end
      end

      it 'validates required field presence' do
        element = double('element', title: nil, level: nil, tags: nil)
        result = schema.validate(element)
        expect(result).not_to be_valid
        expect(result.errors.first.message).to include('title is required')
      end

      it 'validates field type' do
        element = double('element', title: 'Test', level: 'invalid', tags: nil)
        result = schema.validate(element)
        expect(result.errors.any? { |e| e.message.include?('level must be') }).to be true
      end

      it 'validates min_length' do
        element = double('element', title: '', level: nil, tags: nil)
        result = schema.validate(element)
        expect(result.errors.any? { |e| e.code == :min_length }).to be true
      end

      it 'validates min_count' do
        element = double('element', title: 'Test', level: nil, tags: [])
        result = schema.validate(element)
        expect(result.errors.any? { |e| e.code == :min_count }).to be true
      end

      it 'runs custom rules' do
        element = double('element', title: 'A' * 150, level: nil, tags: nil)
        result = schema.validate(element)
        expect(result.errors.any? { |e| e.message == 'Title is too long' }).to be true
      end

      it 'passes valid document' do
        element = double('element', title: 'Test Title', level: 1, tags: %w[a b])
        result = schema.validate(element)
        expect(result).to be_valid
      end
    end
  end

  describe Coradoc::Validation::SchemaGenerator do
    describe '.generate' do
      it 'generates schema from CoreModel class' do
        schema = described_class.generate(Coradoc::CoreModel::StructuralElement)

        expect(schema).to be_a(Coradoc::Validation::Schema)
        expect(schema.fields).to have_key(:id)
        expect(schema.fields).to have_key(:title)
        expect(schema.fields).to have_key(:element_type)
        expect(schema.fields).to have_key(:level)
        expect(schema.fields).to have_key(:children)
      end

      it 'marks specified attributes as required' do
        schema = described_class.generate(
          Coradoc::CoreModel::StructuralElement,
          required: %i[title element_type]
        )

        expect(schema.fields[:title][:required]).to be true
        expect(schema.fields[:element_type][:required]).to be true
      end

      it 'ignores specified attributes' do
        schema = described_class.generate(
          Coradoc::CoreModel::StructuralElement,
          ignored: %i[metadata attributes]
        )

        expect(schema.fields).not_to have_key(:metadata)
        expect(schema.fields).not_to have_key(:attributes)
      end

      it 'applies custom rules' do
        schema = described_class.generate(
          Coradoc::CoreModel::StructuralElement,
          custom_rules: {
            level: { min_count: 0 }
          }
        )

        expect(schema.fields[:level][:min_count]).to eq(0)
      end

      it 'validates document with generated schema' do
        schema = described_class.generate(
          Coradoc::CoreModel::StructuralElement,
          required: [:element_type]
        )

        element = Coradoc::CoreModel::StructuralElement.new(
          element_type: 'section',
          level: 1,
          title: 'Test'
        )

        result = schema.validate(element)
        expect(result).to be_valid
      end

      it 'catches validation errors with generated schema' do
        schema = described_class.generate(
          Coradoc::CoreModel::StructuralElement,
          required: [:element_type]
        )

        element = Coradoc::CoreModel::StructuralElement.new(
          element_type: nil,
          level: 1
        )

        result = schema.validate(element)
        expect(result).not_to be_valid
        expect(result.errors.any? { |e| e.code == :required }).to be true
      end

      it 'returns nil for non-model class' do
        schema = described_class.generate(String)
        expect(schema).to be_nil
      end
    end

    describe '.map_type' do
      it 'maps Lutaml::Model type classes to Ruby classes' do
        expect(described_class.map_type(Lutaml::Model::Type::String)).to eq(String)
        expect(described_class.map_type(Lutaml::Model::Type::Integer)).to eq(Integer)
        expect(described_class.map_type(Lutaml::Model::Type::Float)).to eq(Float)
        expect(described_class.map_type(Lutaml::Model::Type::Hash)).to eq(Hash)
      end

      it 'returns class for CoreModel types' do
        expect(described_class.map_type(Coradoc::CoreModel::Base)).to eq(Coradoc::CoreModel::Base)
      end

      it 'returns Object for other Lutaml types' do
        expect(described_class.map_type(Lutaml::Model::Type::Boolean)).to eq([TrueClass, FalseClass])
      end
    end
  end

  describe '.auto_schema' do
    it 'generates schema from CoreModel class' do
      schema = described_class.auto_schema(Coradoc::CoreModel::Block)

      expect(schema).to be_a(Coradoc::Validation::Schema)
      expect(schema.fields).to have_key(:content)
      expect(schema.fields).to have_key(:delimiter_type)
    end

    it 'passes options to generator' do
      schema = described_class.auto_schema(
        Coradoc::CoreModel::Block,
        required: [:content],
        ignored: [:metadata]
      )

      expect(schema.fields[:content][:required]).to be true
      expect(schema.fields).not_to have_key(:metadata)
    end

    it 'validates documents correctly' do
      schema = described_class.auto_schema(
        Coradoc::CoreModel::Block,
        required: [:content]
      )

      block = Coradoc::CoreModel::Block.new(
        element_type: 'paragraph',
        content: 'Test content'
      )

      result = schema.validate(block)
      expect(result).to be_valid
    end
  end

  describe Coradoc::Validation::Rules::Required do
    it 'returns error when field is nil' do
      element = double('element', name: nil)
      rule = described_class.new(:required, field: :name)
      errors = rule.validate(element)
      expect(errors).to eq(['name is required'])
    end

    it 'returns no error when field is present' do
      element = double('element', name: 'Test')
      rule = described_class.new(:required, field: :name)
      errors = rule.validate(element)
      expect(errors).to eq([])
    end
  end

  describe Coradoc::Validation::Rules::Type do
    it 'returns error when type mismatch' do
      element = double('element', count: 'five')
      rule = described_class.new(:type, field: :count, type: Integer)
      errors = rule.validate(element)
      expect(errors.first).to include('count must be Integer')
    end

    it 'returns no error when type matches' do
      element = double('element', count: 5)
      rule = described_class.new(:type, field: :count, type: Integer)
      errors = rule.validate(element)
      expect(errors).to eq([])
    end

    it 'returns no error when field is nil and not required' do
      element = double('element', count: nil)
      rule = described_class.new(:type, field: :count, type: Integer, required: false)
      errors = rule.validate(element)
      expect(errors).to eq([])
    end
  end

  describe Coradoc::Validation::Rules::Length do
    it 'returns error when below min' do
      element = double('element', title: 'AB')
      rule = described_class.new(:length, field: :title, min: 5)
      errors = rule.validate(element)
      expect(errors.first).to include('at least 5 characters')
    end

    it 'returns error when above max' do
      element = double('element', title: 'A' * 150)
      rule = described_class.new(:length, field: :title, max: 100)
      errors = rule.validate(element)
      expect(errors.first).to include('at most 100 characters')
    end

    it 'returns no error when within bounds' do
      element = double('element', title: 'Valid Title')
      rule = described_class.new(:length, field: :title, min: 1, max: 100)
      errors = rule.validate(element)
      expect(errors).to eq([])
    end
  end

  describe Coradoc::Validation::Rules::Count do
    it 'returns error when below min count' do
      element = double('element', items: [1, 2])
      rule = described_class.new(:count, field: :items, min: 3)
      errors = rule.validate(element)
      expect(errors.first).to include('at least 3 items')
    end

    it 'returns error when above max count' do
      element = double('element', items: (1..15).to_a)
      rule = described_class.new(:count, field: :items, max: 10)
      errors = rule.validate(element)
      expect(errors.first).to include('at most 10 items')
    end

    it 'returns no error when within bounds' do
      element = double('element', items: [1, 2, 3, 4, 5])
      rule = described_class.new(:count, field: :items, min: 1, max: 10)
      errors = rule.validate(element)
      expect(errors).to eq([])
    end
  end

  describe Coradoc::Validation::Rules::Format do
    it 'returns error when format mismatch' do
      element = double('element', email: 'invalid-email')
      rule = described_class.new(:format, field: :email, pattern: /\A[^@]+@[^@]+\z/)
      errors = rule.validate(element)
      expect(errors).to eq(['email has invalid format'])
    end

    it 'returns no error when format matches' do
      element = double('element', email: 'test@example.com')
      rule = described_class.new(:format, field: :email, pattern: /\A[^@]+@[^@]+\z/)
      errors = rule.validate(element)
      expect(errors).to eq([])
    end
  end

  describe Coradoc::Validation::Rules::Custom do
    it 'executes custom block' do
      element = double('element', value: 5)
      rule = described_class.new(:custom, block: lambda { |el, _ctx|
        el.value > 10 ? ['Value must be <= 10'] : []
      })
      errors = rule.validate(element)
      expect(errors).to eq([])

      element2 = double('element', value: 15)
      errors2 = rule.validate(element2)
      expect(errors2).to eq(['Value must be <= 10'])
    end
  end

  describe '.define' do
    it 'creates schema via module method' do
      schema = described_class.define do
        required :name, type: String
      end

      expect(schema).to be_a(Coradoc::Validation::Schema)
      expect(schema.fields[:name][:required]).to be true
    end
  end

  describe '.validate' do
    it 'validates with default schema' do
      element = double('element', id: 'test', title: 'Test')
      result = described_class.validate(element)
      expect(result).to be_valid
    end
  end

  describe '.default_schema' do
    it 'returns default schema' do
      schema = described_class.default_schema
      expect(schema).to be_a(Coradoc::Validation::Schema)
      expect(schema.fields[:id][:required]).to be false
      expect(schema.fields[:title][:required]).to be false
    end
  end

  describe '.default_schema=' do
    it 'sets custom default schema' do
      custom_schema = Coradoc::Validation::Schema.define do
        required :custom_field
      end

      original_schema = described_class.default_schema
      described_class.default_schema = custom_schema

      expect(described_class.default_schema).to eq(custom_schema)

      # Restore original
      described_class.default_schema = original_schema
    end
  end
end
