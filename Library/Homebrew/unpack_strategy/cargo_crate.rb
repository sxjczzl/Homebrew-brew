# typed: true
# frozen_string_literal: true

require_relative "tar"

module UnpackStrategy
  # Strategy for unpacking Cargo crates.
  class CargoCrate < Tar
    extend T::Sig

    using Magic

    sig { returns(T::Array[String]) }
    def self.extensions
      [".crate"].freeze
    end

    def self.can_extract?(path)
      Tar.can_extract?(path) && path.magic_number.match?(/\.crate\b/n)
    end
  end
end
