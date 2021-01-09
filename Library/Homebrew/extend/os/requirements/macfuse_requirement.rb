# typed: strict
# frozen_string_literal: true

if OS.mac?
  require "extend/os/mac/requirements/macfuse_requirement"
elsif OS.linux?
  require "extend/os/linux/requirements/macfuse_requirement"
end
