# frozen_string_literal: true

require 'coradoc'
require 'coradoc/mirror'

# Side-effect: registers output processors with Coradoc::Output pipeline.
# Side-effect: registers format modules with Coradoc registry.
# These must use require (not autoload) because they have load-time side effects.
require 'coradoc/mirror/output'
require 'coradoc/mirror/mirror_json_format'
require 'coradoc/mirror/mirror_yaml_format'

# Ensure Coradoc error classes are loaded (autoloaded via Coradoc::Error).
Coradoc::Error
