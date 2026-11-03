# frozen_string_literal: true

module Coradoc
  module Roundtrip
    # One round-trip input: a fixture file or a generated edge case.
    Case = Struct.new(:id, :format, :text, :origin) do
      # @return [String] a short label for failure reports
      def to_s = id
    end
  end
end
