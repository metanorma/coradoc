# frozen_string_literal: true

module Coradoc
  module Model
    class Revision < Base
      attribute :number, :string
      attribute :date, :date
      attribute :remark, :string

      asciidoc do
        map_attribute "number", to: :number
        map_attribute "date", to: :date
        map_attribute "remark", to: :remark
      end

      def to_asciidoc
        if date.nil? && remark.nil?
          "v#{number}\n"
        elsif remark.nil?
          "#{number}, #{date}\n"
        elsif date.nil?
          "#{number}: #{remark}\n"
        else
          "#{number}, #{date}: #{remark}\n"
        end
      end

    end
  end
end
