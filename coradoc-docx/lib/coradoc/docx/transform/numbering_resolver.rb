# frozen_string_literal: true

module Coradoc
  module Docx
    module Transform
      # Resolves OOXML numbering definitions to list style information.
      #
      # OOXML stores list formatting in numbering definitions (abstractNum).
      # Each numPr reference (numId + ilvl) points to a specific numbering
      # format (bullet, decimal, lowerLetter, etc.).
      #
      # The resolver walks Uniword's NumberingConfiguration to build a map
      # of numId → { ordered, marker_type, format }.
      class NumberingResolver
        ORDERED_FORMATS = %w[decimal lowerLetter upperLetter lowerRoman upperRoman
                             russianLower russianUpper hebrew1 hebrew2 thaiLetters
                             japaneseDigitalTenji japaneseKorean chineseCounting].freeze

        # @param numbering_configuration [Object, nil] Uniword numbering config
        def initialize(numbering_configuration)
          @config = numbering_configuration
          @num_map = build_num_map(numbering_configuration)
        end

        # Determine if a numId represents an ordered list
        #
        # @param num_id [Integer, String, nil] numbering definition ID
        # @return [Boolean] true if ordered, false if unordered
        def ordered?(num_id)
          return false unless num_id

          info = @num_map[num_id.to_i]
          return false unless info

          info[:ordered]
        end

        # Get the list style for a numId
        #
        # @param num_id [Integer, String, nil]
        # @return [Symbol] :ordered, :unordered
        def list_style(num_id)
          ordered?(num_id) ? :ordered : :unordered
        end

        # Get marker type string for a numId
        #
        # @param num_id [Integer, String, nil]
        # @return [String] "numbered", "asterisk", "lower_alpha", etc.
        def marker_type(num_id)
          return 'asterisk' unless num_id

          info = @num_map[num_id.to_i]
          return 'asterisk' unless info

          info[:marker_type]
        end

        private

        def build_num_map(config)
          return {} unless config

          instances = config.respond_to?(:instances) ? config.instances : []
          return {} if instances.empty?

          map = {}
          instances.each do |inst|
            num_id = inst.num_id
            abstract_num_id = extract_abstract_num_id(inst)
            next unless num_id && abstract_num_id

            definition = find_definition(config, abstract_num_id)
            next unless definition

            levels = definition.respond_to?(:levels) ? definition.levels : []
            level = levels.first
            next unless level

            fmt = extract_num_fmt(level)
            ordered = ORDERED_FORMATS.include?(fmt)
            map[num_id] = {
              ordered: ordered,
              marker_type: marker_type_for(fmt),
              format: fmt
            }
          end

          map
        end

        def extract_abstract_num_id(instance)
          aid = instance.abstract_num_id
          return nil unless aid

          aid.respond_to?(:value) ? aid.value : aid
        end

        def find_definition(config, abstract_num_id)
          defs = config.respond_to?(:definitions) ? config.definitions : []
          defs.find { |d| d.abstract_num_id == abstract_num_id }
        end

        def extract_num_fmt(level)
          nf = level.numFmt
          return 'bullet' unless nf

          nf.respond_to?(:val) ? nf.val.to_s : nf.to_s
        end

        def marker_type_for(fmt)
          case fmt
          when 'decimal' then 'numbered'
          when 'lowerLetter' then 'lower_alpha'
          when 'upperLetter' then 'upper_alpha'
          when 'lowerRoman' then 'lower_roman'
          when 'upperRoman' then 'upper_roman'
          when 'bullet' then 'asterisk'
          else 'numbered'
          end
        end
      end
    end
  end
end
