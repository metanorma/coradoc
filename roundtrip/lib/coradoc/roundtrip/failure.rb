# frozen_string_literal: true

module Coradoc
  module Roundtrip
    # A violated round-trip property, located by construct path and snippet.
    #
    # @!attribute stage [Symbol] :parse, :serialize, :reparse, :model or :canonical
    # @!attribute path [String] model path (model stage) or line locator (text stages)
    # @!attribute snippet [String] the offending source text or the differing values
    Failure = Struct.new(:case_id, :stage, :path, :snippet, :message) do
      def to_s
        ["#{case_id} [#{stage}] at #{path}", message, snippet].compact.reject(&:empty?).join("\n")
      end
    end
  end
end
