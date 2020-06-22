# frozen_string_literal: true

class SwiftRequirement < Requirement
  fatal true

  attr_reader :version

  def initialize(tags = [])
    @version = tags.shift if tags.first.to_s.match?(/(\d\.)+\d/)
    super(tags)
  end

  def inspect
    "#<#{self.class.name}: #{tags.inspect} version=#{@version.inspect}>"
  end

  def message
    "Swift #{@version} is required to compile this software."
  end
end

require "extend/os/requirements/swift_requirement"
