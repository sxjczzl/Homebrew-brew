# typed: false
# frozen_string_literal: true

require_relative "shared_examples/base"
require_relative "shared_examples/staged"

describe Cask::DSL::Postflight, :cask do
  let(:cask) { Cask::CaskLoader.load(cask_path("basic-cask")) }
  let(:dsl) { described_class.new(instance_double(Cask::DSL, cask: cask), FakeSystemCommand) }

  it_behaves_like Cask::DSL::Base

  it_behaves_like Cask::Staged do
    let(:staged) { dsl }
  end
end
