# frozen_string_literal: true

require "cask/all"

module Homebrew
  module_function

  def cask
    Cask::Cmd.run(*Homebrew.args)
  end
end
