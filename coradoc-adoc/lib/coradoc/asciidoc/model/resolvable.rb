# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      # Module for nodes that reference external resources.
      #
      # Any model element that references an external file or resource
      # should include this module to provide a unified interface for
      # resolution operations.
      #
      # @example Implementing Resolvable in a class
      #   class Include < Base
      #     include Resolvable
      #
      #     def reference_path
      #       path
      #     end
      #
      #     def reference_type
      #       :include
      #     end
      #   end
      #
      module Resolvable
        # Returns the path to the external resource.
        #
        # @return [String] the path or URL to the external resource
        # @raise [NotImplementedError] if not implemented by including class
        def reference_path
          raise NotImplementedError,
                "#{self.class} must implement #reference_path"
        end

        # Returns the type of reference.
        #
        # @return [Symbol] the reference type (:include, :image, :video, :audio, :link)
        # @raise [NotImplementedError] if not implemented by including class
        def reference_type
          raise NotImplementedError,
                "#{self.class} must implement #reference_type"
        end

        # Returns additional options for reference resolution.
        #
        # @return [Hash] options for resolution (e.g., leveloffset, lines, tags)
        def reference_options
          {}
        end

        # Checks if the reference is to a local file.
        #
        # @return [Boolean] true if the reference is a local file path
        def local_reference?
          path = reference_path
          return false if path.nil?

          # Not a URL if it doesn't start with a scheme
          !path.match?(%r{^[a-z][a-z0-9+.-]*://}i)
        end

        # Checks if the reference is to a remote URL.
        #
        # @return [Boolean] true if the reference is a URL
        def remote_reference?
          !local_reference?
        end
      end
    end
  end
end
