require "open3"

# class for reading and writing extended attributes
module LSQuarantine
  class ExtendedAttributes
    def initialize(file, follow_symlinks: false)
      @file = File.new(file)
      @follow_symlinks = follow_symlinks
    end

    def list
      out, status = command

      return nil unless status.success?
      return [] if out.empty?

      out.chomp.split(/\n/)
    end

    def to_h
      lst = list

      return nil if lst.nil?

      list.each_with_object({}) do |attribute, hash|
        hash[attribute] = get(attribute)
      end
    end

    def set(name, content)
      command("-w", name, content)[1].success?
    end

    def get(name)
      out, status = command("-x", "-p", name)

      return nil unless status.success?

      # `xattr -x` outputs hex-string with line breaks and spaces
      [out.delete("\n\s")].pack("H*")
    end

    def remove(name)
      command("-d", name)
      !(list || []).include?(name)
    end

    def clear
      command("-c")[1].success?
    end

    private

    XATTR_EXECUTABLE = "/usr/bin/xattr".freeze

    def command(*args)
      args.unshift("-s") unless @follow_symlinks

      out, error, status = Open3.capture3(XATTR_EXECUTABLE, *args, @file.path)
      out = nil unless status.success? && error.empty?

      [out, status]
    end
  end
end
