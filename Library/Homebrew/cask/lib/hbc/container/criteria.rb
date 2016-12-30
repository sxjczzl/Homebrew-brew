module Hbc
  class Container
    class Criteria
      attr_reader :path, :command

      def initialize(path, command)
        @path = path
        @command = command
      end

      def extension(regex)
        effective_filename = @command.run!("/usr/bin/xattr", args: ["-p", "curl.filename_effective", @path]).stdout.chomp

        path = if effective_filename.empty?
          @path
        else
          Pathname.new(effective_filename)
        end

        path.extname.sub(/^\./, "") =~ Regexp.new(regex.source, regex.options | Regexp::IGNORECASE)
      end

      def magic_number(regex)
        # 262: length of the longest regex (currently: Hbc::Container::Tar)
        @magic_number ||= File.open(@path, "rb") { |f| f.read(262) }
        @magic_number =~ regex
      end
    end
  end
end
