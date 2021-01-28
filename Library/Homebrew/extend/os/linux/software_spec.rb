# typed: true
# frozen_string_literal: true

class SoftwareSpec
  extend T::Sig

  GNU_GCC_REGEXP = /^(gcc)$|^(gcc@(4\.9|[5-9]|[10-99]))$/.freeze

  sig { params(spec: T.any(String, T::Hash[T.untyped, T.untyped])).void }
  def remove_gnu_compilers(spec)
    spec = spec.keys.first if spec.is_a?(Hash)
    return unless spec.is_a?(String)
    return unless spec.match?(GNU_GCC_REGEXP)

    # When a formula explicitely depends on a specific gcc compiler,
    # remove the other compilers to avoid having to define fails_with
    # manually for all the others compiler versions.
    gcc_version_to_keep = Formulary.factory(spec).version.to_s.slice(/\d+/)

    versions = CompilerConstants::GNU_GCC_VERSIONS

    if spec == "gcc"
      # Special case for gcc: in linuxbrew-core, gcc is currently at version 5,
      # so when we use 'depend_on "gcc"' we do not want to remove version 5.
      # Once https://github.com/Homebrew/linuxbrew-core/pull/21380 is merged,
      # this line becomes useless and we can remove the whole if/else logic
      versions -= [gcc_version_to_keep] if gcc_version_to_keep != "5"
    else
      versions -= [gcc_version_to_keep]
    end

    versions.each do |v|
      fails_with("gcc-#{v}")
    end
  end
end

class BottleSpecification
  extend T::Sig
  sig { returns(T::Boolean) }
  def skip_relocation?
    false
  end
end
