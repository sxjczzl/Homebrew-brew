module OS
  module Cygwin
    module DLL
      module_function

      def version
        return @version if @version

        version = Utils.popen_read("uname", "-r").chomp
        return Version::NULL unless version

        @version = Version.new version
      end

      def minimum_version
        Version.new "3.0.0"
      end

      def below_minimum_version?
        version < minimum_version
      end
    end
  end
end
