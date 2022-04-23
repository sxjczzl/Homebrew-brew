# typed: strict
# frozen_string_literal: true

# This file should be the first `require` in all entrypoints of `brew`.

require_relative "standalone/load_path"
require_relative "startup/ruby_path"
require_relative "startup/env_var"
require "startup/config"
require_relative "startup/bootsnap"
require_relative "startup/sorbet"
