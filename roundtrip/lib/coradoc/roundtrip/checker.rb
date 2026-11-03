# frozen_string_literal: true

require 'timeout'

module Coradoc
  module Roundtrip
    # Runs the round trip for one Case and reports the first violated property.
    class Checker
      # Seconds one case may take; a parser that does not finish is a failure,
      # not a hung CI job. Override with CORADOC_ROUNDTRIP_TIMEOUT.
      TIMEOUT = Integer(ENV.fetch('CORADOC_ROUNDTRIP_TIMEOUT', 20))

      # @param kase [Case]
      # @return [Failure, nil] nil when the case round-trips
      def call(kase)
        Timeout.timeout(TIMEOUT) { check(kase) }
      rescue Timeout::Error
        Failure.new(kase.id, :timeout, "over #{TIMEOUT}s", Snippet.around(kase.text, 1),
                    'parse/serialize did not finish in time')
      end

      private

      def check(kase)
        format = kase.format
        core1 = stage(kase, :parse, kase.text) { Coradoc.parse(kase.text, format: format) }
        return core1 if core1.is_a?(Failure)

        text1 = stage(kase, :serialize, kase.text) { Coradoc.serialize(core1, to: format) }
        return text1 if text1.is_a?(Failure)

        core2 = stage(kase, :reparse, text1) { Coradoc.parse(text1, format: format) }
        return core2 if core2.is_a?(Failure)

        model_failure(kase, core1, core2, text1) || canonical_failure(kase, core2, text1)
      end

      def stage(kase, name, source)
        yield
      rescue StandardError => e
        Failure.new(kase.id, name, e.backtrace_locations&.first.to_s,
                    Snippet.around(source, 1), "#{e.class}: #{e.message.lines.first&.chomp}")
      end

      # core1 and core2 must be structurally identical. The excerpt shows
      # the canonical text around the construct where they diverge.
      def model_failure(kase, core1, core2, text1)
        path, left, right = Projection.first_difference(Projection.of(core1), Projection.of(core2))
        return unless path

        Failure.new(kase.id, :model, path, "first: #{short(left)}\nagain: #{short(right)}\n#{canonical_hint(text1, left)}",
                    'CoreModel changed on re-parse of the serialized output')
      end

      # serialize(parse(T1)) must equal T1: the canonical form is a fixed point.
      def canonical_failure(kase, core2, text1)
        text2 = Coradoc.serialize(core2, to: kase.format)
        return if text2 == text1

        line = Snippet.first_difference(text1, text2)
        Failure.new(kase.id, :canonical, "line #{line}",
                    "first pass:\n#{Snippet.around(text1, line)}\nsecond pass:\n#{Snippet.around(text2, line)}",
                    'serialized output is not a fixed point of parse+serialize')
      rescue StandardError => e
        Failure.new(kase.id, :canonical, 'serialize', '', "#{e.class}: #{e.message.lines.first&.chomp}")
      end

      def canonical_hint(text1, value)
        needle = value.to_s.lines.first.to_s.strip[0, 40]
        return '' if needle.empty?

        line = text1.lines.index { |l| l.include?(needle) }
        line ? "near canonical output:\n#{Snippet.around(text1, line + 1)}" : ''
      end

      def short(value)
        text = value.inspect
        text.length > 200 ? "#{text[0, 200]}…" : text
      end
    end
  end
end
