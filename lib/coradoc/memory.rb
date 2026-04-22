# frozen_string_literal: true

module Coradoc
  # Memory profiling and monitoring utilities.
  #
  # This module provides utilities for monitoring memory usage during
  # document processing operations. It helps identify memory-intensive
  # operations and potential memory leaks.
  #
  # @example Basic memory profiling
  #   Coradoc::Memory.profile do
  #     doc = Coradoc.parse(large_text, format: :asciidoc)
  #     html = Coradoc.serialize(doc, to: :html)
  #   end
  #   # => { allocated: 1500000, retained: 500000, peak: 2000000 }
  #
  # @example Tracking memory over time
  #   tracker = Coradoc::Memory::Tracker.new
  #   tracker.checkpoint("start")
  #   doc = Coradoc.parse(text, format: :asciidoc)
  #   tracker.checkpoint("after_parse")
  #   html = Coradoc.serialize(doc, to: :html)
  #   tracker.checkpoint("after_serialize")
  #   tracker.report
  #
  module Memory
    # Memory usage snapshot
    class Snapshot
      attr_reader :timestamp, :allocated_objects, :heap_slots,
                  :heap_slots_live, :total_memsize, :gc_count

      # Create a memory snapshot
      #
      # @return [Snapshot] Current memory state
      def self.take
        gc_stats = GC.stat
        new(
          timestamp: Time.now,
          allocated_objects: gc_stats[:total_allocated_objects] || 0,
          heap_slots: gc_stats[:heap_sorted_length] || gc_stats[:heap_length] || 0,
          heap_slots_live: gc_stats[:heap_live_slot] || gc_stats[:heap_slots] || 0,
          total_memsize: calculate_total_memsize,
          gc_count: gc_stats[:count] || 0
        )
      end

      # Calculate total memory size of all objects
      #
      # @return [Integer] Total memory in bytes
      def self.calculate_total_memsize
        total = 0
        ObjectSpace.each_object { |obj| total += ObjectSpace.memsize_of(obj) }
        total
      rescue StandardError
        0
      end

      def initialize(timestamp:, allocated_objects:, heap_slots:,
                     heap_slots_live:, total_memsize:, gc_count:)
        @timestamp = timestamp
        @allocated_objects = allocated_objects
        @heap_slots = heap_slots
        @heap_slots_live = heap_slots_live
        @total_memsize = total_memsize
        @gc_count = gc_count
      end

      # Calculate difference from another snapshot
      #
      # @param other [Snapshot] Another snapshot
      # @return [Hash] Difference in values
      def diff(other)
        {
          elapsed: timestamp - other.timestamp,
          allocated_delta: allocated_objects - other.allocated_objects,
          heap_delta: heap_slots - other.heap_slots,
          live_delta: heap_slots_live - other.heap_slots_live,
          memsize_delta: total_memsize - other.total_memsize,
          gc_runs: gc_count - other.gc_count
        }
      end

      # Convert to hash
      #
      # @return [Hash]
      def to_h
        {
          timestamp: timestamp,
          allocated_objects: allocated_objects,
          heap_slots: heap_slots,
          heap_slots_live: heap_slots_live,
          total_memsize: total_memsize,
          gc_count: gc_count
        }
      end
    end

    # Memory tracker for capturing checkpoints
    class Tracker
      attr_reader :checkpoints

      # Create a new memory tracker
      #
      # @param auto_gc [Boolean] Whether to run GC before each checkpoint
      def initialize(auto_gc: true)
        @auto_gc = auto_gc
        @checkpoints = []
      end

      # Record a checkpoint
      #
      # @param name [String] Checkpoint name
      # @return [Snapshot] The recorded snapshot
      def checkpoint(name)
        GC.start if @auto_gc
        snapshot = Snapshot.take
        @checkpoints << { name: name, snapshot: snapshot }
        snapshot
      end

      # Get memory usage between checkpoints
      #
      # @return [Array<Hash>] List of memory deltas
      def deltas
        return [] if @checkpoints.size < 2

        @checkpoints.each_cons(2).map do |previous, current|
          {
            from: previous[:name],
            to: current[:name],
            delta: current[:snapshot].diff(previous[:snapshot])
          }
        end
      end

      # Generate a report
      #
      # @return [String] Formatted report
      def report
        return 'No checkpoints recorded' if @checkpoints.empty?

        lines = ['Memory Profile Report', '=' * 50]
        lines << ''

        if @checkpoints.size == 1
          cp = @checkpoints.first
          lines << "Single checkpoint: #{cp[:name]}"
          lines << "  Allocated objects: #{cp[:snapshot].allocated_objects}"
          lines << "  Total memory: #{format_bytes(cp[:snapshot].total_memsize)}"
        else
          deltas.each do |delta|
            lines << "#{delta[:from]} -> #{delta[:to]}:"
            lines << "  Time: #{delta[:delta][:elapsed].round(3)}s"
            lines << "  Allocated: #{delta[:delta][:allocated_delta]}"
            lines << "  Memory: #{format_bytes(delta[:delta][:memsize_delta])}"
            lines << "  GC runs: #{delta[:delta][:gc_runs]}"
            lines << ''
          end

          total = @checkpoints.last[:snapshot].diff(@checkpoints.first[:snapshot])
          lines << 'Total:'
          lines << "  Time: #{total[:elapsed].round(3)}s"
          lines << "  Allocated: #{total[:allocated_delta]}"
          lines << "  Memory: #{format_bytes(total[:memsize_delta])}"
        end

        lines.join("\n")
      end

      private

      def format_bytes(bytes)
        return '0 B' if bytes.nil? || bytes.zero?

        units = %w[B KB MB GB]
        size = bytes.abs.to_f
        unit = 0

        while size > 1024 && unit < units.length - 1
          size /= 1024
          unit += 1
        end

        format('%<size>.2f %<unit>s', size: size, unit: units[unit])
      end
    end

    # Profile result
    class ProfileResult
      attr_reader :allocated, :retained, :peak, :duration

      def initialize(allocated:, retained:, peak:, duration:)
        @allocated = allocated
        @retained = retained
        @peak = peak
        @duration = duration
      end

      def to_h
        {
          allocated: allocated,
          retained: retained,
          peak: peak,
          duration: duration
        }
      end

      def to_s
        "Allocated: #{format_bytes(allocated)}, " \
        "Retained: #{format_bytes(retained)}, " \
        "Peak: #{format_bytes(peak)}, " \
        "Duration: #{duration.round(3)}s"
      end

      private

      def format_bytes(bytes)
        return '0 B' if bytes.nil? || bytes.zero?

        units = %w[B KB MB GB]
        size = bytes.abs.to_f
        unit = 0

        while size > 1024 && unit < units.length - 1
          size /= 1024
          unit += 1
        end

        format('%<size>.2f %<unit>s', size: size, unit: units[unit])
      end
    end

    class << self
      # Get current memory usage
      #
      # @return [Integer] Memory usage in bytes (approximate)
      def current_usage
        GC.stat[:total_allocated_objects] * 8 # Rough estimate
      end

      # Get detailed memory statistics
      #
      # @return [Hash] Memory statistics
      def stats
        gc_stats = GC.stat
        {
          total_allocated_objects: gc_stats[:total_allocated_objects],
          heap_sorted_length: gc_stats[:heap_sorted_length],
          heap_live_slots: gc_stats[:heap_live_slot],
          heap_free_slots: gc_stats[:heap_free_slot],
          gc_count: gc_stats[:count],
          gc_time: gc_stats[:time] || 0
        }
      end

      # Profile a block of code
      #
      # @param gc_before [Boolean] Run GC before profiling
      # @param gc_after [Boolean] Run GC after profiling
      # @yield Block to profile
      # @return [ProfileResult] Profiling results
      def profile(gc_before: true, gc_after: true)
        GC.start if gc_before

        start_snapshot = Snapshot.take
        start_time = Time.now
        peak_memory = start_snapshot.total_memsize

        # Track peak memory during execution
        peak_tracker = Thread.new do
          loop do
            sleep(0.01)
            current = Snapshot.take.total_memsize
            peak_memory = current if current > peak_memory
          end
        end

        begin
          yield
        ensure
          peak_tracker.kill
          GC.start if gc_after
        end

        end_snapshot = Snapshot.take
        duration = Time.now - start_time

        ProfileResult.new(
          allocated: end_snapshot.total_memsize - start_snapshot.total_memsize,
          retained: end_snapshot.total_memsize - start_snapshot.total_memsize,
          peak: peak_memory - start_snapshot.total_memsize,
          duration: duration
        )
      end

      # Create a new tracker
      #
      # @param auto_gc [Boolean] Whether to run GC before each checkpoint
      # @return [Tracker]
      def tracker(auto_gc: true)
        Tracker.new(auto_gc: auto_gc)
      end

      # Take a memory snapshot
      #
      # @return [Snapshot]
      def snapshot
        Snapshot.take
      end

      # Force garbage collection and return memory freed
      #
      # @return [Integer] Approximate bytes freed
      def gc_cleanup
        before = Snapshot.take
        GC.start
        after = Snapshot.take
        before.total_memsize - after.total_memsize
      end
    end
  end
end
