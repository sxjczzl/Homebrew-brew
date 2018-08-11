module UnpackStrategy
  class Directory
    include UnpackStrategy

    using Magic

    def self.extensions
      []
    end

    def self.can_extract?(path)
      path.directory?
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      path.children.each do |child|
        FileUtils.mv child, unpack_dir/child.basename
      end
    end
  end
end
