# frozen_string_literal: true

module Coradoc
  class Logger
    BADGE = 'Coradoc'

    COLORS = {
      error: "\e[31m", # Red
      info: "\e[34m", # Blue
      reset: "\e[m", # Reset
      success: "\e[32m", # Green
      warn: "\e[33m", # Yellow
      bold: "\e[1m",
      unbold: "\e[22m"
    }.freeze

    def self.error(message)
      log(message, :error)
    end

    def self.info(message)
      log(message, :info)
    end

    def self.success(message)
      log(message, :success)
    end

    def self.warn(message)
      log(message, :warn)
    end

    def self.log(message, type)
      Warning.warn format_message(message, type)
    end

    def self.format_message(message, type)
      colorize(
        "\n[#{BADGE}] #{COLORS[:bold]}#{type.upcase}#{COLORS[:unbold]}" \
        ": #{message}\n",
        type
      )
    end

    def self.colorize(message, type)
      io = type == :warn ? $stderr : $stdout
      return message unless io.tty?

      "#{COLORS[type]}#{message}#{COLORS[:reset]}"
    end

    private_class_method :log, :format_message, :colorize
  end
end
