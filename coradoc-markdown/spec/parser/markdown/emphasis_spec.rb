# frozen_string_literal: true

require 'spec_helper'

def split_on_emph(text)
  text.split(/([*_]+)/).filter { |t| !t.empty? }.map { |t| { text: t } }
end
