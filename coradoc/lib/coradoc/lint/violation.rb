# frozen_string_literal: true

module Coradoc
  module Lint
    # One reported rule violation. Plain data — path and rule always
    # present, line nil when the model does not carry source
    # positions.
    Violation = Struct.new(:rule_id, :path, :line, :message, :severity,
                           keyword_init: true) do
      def to_s
        line_part = line ? ":#{line}" : ''
        "#{path}#{line_part} [#{rule_id}] #{message}"
      end
    end
  end
end
