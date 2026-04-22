# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      # Revision information for document headers.
      #
      # Revision metadata tracks document version numbers, dates, and remarks.
      #
      # @!attribute [r] number
      #   @return [String, nil] The revision number (e.g., "1.0", "2.1")
      #
      # @!attribute [r] date
      #   @return [Date, nil] The revision date
      #
      # @!attribute [r] remark
      #   @return [String, nil] Optional revision notes
      #
      # @example Create a revision
      #   rev = Coradoc::AsciiDoc::Model::Revision.new
      #   rev.number = "1.0"
      #   rev.date = Date.new(2024, 1, 15)
      #   rev.remark = "Initial release"
      #
      # @raise [TypeError] if date is not a Date object
      #
      class Revision < Base
        attribute :number, :string
        attribute :date, :date
        attribute :remark, :string

        def validate
          super
          validate_date_type
        end

        private

        def validate_date_type
          return if date.nil? || date.is_a?(Date)

          raise TypeError, "date must be a Date, got #{date.class}"
        end
      end
    end
  end
end
