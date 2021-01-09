# typed: strict
# frozen_string_literal: true

require "requirement"

# A requirement on FUSE for macOS.
#
# @api private
class MacfuseRequirement < Requirement
  extend T::Sig
  cask "macfuse"
  fatal true

  sig { returns(String) }
  def display_s
    "FUSE"
  end
end

require "extend/os/requirements/macfuse_requirement"
