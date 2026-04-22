# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Transform
      autoload :Registry, "#{__dir__}/transform/registry"
      autoload :ToCoreModel, "#{__dir__}/transform/to_core_model"
      autoload :ToCoreModelRegistrations, "#{__dir__}/transform/to_core_model_registrations"
      autoload :FromCoreModel, "#{__dir__}/transform/from_core_model"
      autoload :FromCoreModelRegistrations, "#{__dir__}/transform/from_core_model_registrations"
    end
  end
end
