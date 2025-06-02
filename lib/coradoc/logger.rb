# frozen_string_literal: true

module Coradoc
  class Logger
    BADGE = "Coradoc"

    COLORS = {
      error: "\e[31m", # Red
      info: "\e[34m", # Blue
      reset: "\e[m", # Reset
      success: "\e[32m", # Green
      warn: "\e[33m", # Yellow
      bold: "\e[1m",
      unbold: "\e[22m",
    }.freeze

    def self.error(message)
      new.call(message, :error)
    end

    def self.info(message)
      new.call(message, :info)
    end

    def self.success(message)
      new.call(message, :success)
    end

    def self.warn(message)
      new.call(message, :warn)
    end

    def call(message, type)
      Warning.warn format_message(message, type)
    end

    private

    def color(type)
      if COLORS.keys.include?(type)
        COLORS[type]
      else
        raise ArgumentError,
              "Unknown log type: #{type}. Available types: #{COLORS.keys.join(', ')}"
      end
    end

    def colorize(message, type)
      io = type == :warn ? $stderr : $stdout
      return message unless io.tty?

      "#{color(type)}#{message}#{COLORS[:reset]}"
    end

    def format_message(message, type)
      colorize(
        "\n[#{BADGE}] #{COLORS[:bold]}#{type.upcase}#{COLORS[:unbold]}" \
        ": #{message}\n",
        type,
      )
    end
  end
end
