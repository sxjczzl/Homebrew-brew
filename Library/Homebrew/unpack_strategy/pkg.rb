require_relative "uncompressed"

module UnpackStrategy
  class Pkg < Uncompressed
    using Magic

    def self.extensions
      [".pkg", ".mkpg"]
    end

    def self.can_extract?(path)
      path.extname.match?(/\A.m?pkg\Z/) &&
        (path.directory? || path.magic_number.match?(/\Axar!/n))
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      if path.directory?
        super
      else
        system_command! "xar",
                        args:    ["-x", "-f", path, "-C", unpack_dir],
                        verbose: verbose
      end
    end
  end
end
