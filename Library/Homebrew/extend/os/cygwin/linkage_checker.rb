class LinkageChecker
  # Libraries provided by glibc and gcc.
  SYSTEM_LIBRARY_WHITELIST = %w[
    cygcrypt-0.dll
    cygcrype-2.dll
    cyggomp-1.dll
    cygstdc++-6.dll
  ].freeze

  def check_dylibs(rebuild_cache:)
    generic_check_dylibs(rebuild_cache: rebuild_cache)

    # glibc and gcc are implicit dependencies.
    # No other linkage to system libraries is expected or desired.
    @unwanted_system_dylibs = @system_dylibs.reject do |s|
      SYSTEM_LIBRARY_WHITELIST.include? File.basename(s)
    end
    @undeclared_deps -= ["gcc", "glibc"]
  end
end
