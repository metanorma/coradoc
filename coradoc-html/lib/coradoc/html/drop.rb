# frozen_string_literal: true

# Drop namespace — manages Liquid drop layer for template rendering.
#
# Loading order matters: Base must load before DropFactory, and all
# concrete drops must load after DropFactory (they self-register).
# Each drop calls DropFactory.register at load time.
module Coradoc
  module Html
    module Drop
    end
  end
end

# Base must load first (DropFactory depends on it)
require_relative 'drop/base'
# DropFactory loads next
require_relative 'drop/drop_factory'
