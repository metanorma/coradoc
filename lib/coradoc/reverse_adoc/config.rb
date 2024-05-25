require "tmpdir"

module Coradoc::ReverseAdoc
  class Config
    def initialize
      @unknown_tags     = :pass_through
      @input_format     = :html
      @mathml2asciimath = false
      @external_images  = false

      # Destination to save file and images
      @destination      = nil

      # Source of HTML
      # @sourcedir        = nil

      # Image counter, assuming there are max 999 images
      @image_counter = 1
      # pad with 0s
      @image_counter_pattern = "%03d"

      @em_delimiter     = "_".freeze
      @strong_delimiter = "*".freeze
      @inline_options   = {}
      @tag_border       = " ".freeze

      # Plugin system
      @plugins          = []

      # Debugging options
      @track_time       = false
    end

    def with(options = {})
      old_options = @inline_options
      @inline_options = options
      result = yield
      @inline_options = old_options
      result
    end

    def self.declare_option(option)
      define_method(option) do
        @inline_options[option] || instance_variable_get(:"@#{option}")
      end

      attr_writer option
    end

    declare_option :unknown_tags
    declare_option :tag_border
    declare_option :mathml2asciimath
    declare_option :external_images
    declare_option :destination
    declare_option :sourcedir
    declare_option :image_counter
    declare_option :image_counter_pattern
    declare_option :input_format
    declare_option :plugins
    declare_option :track_time
  end
end
