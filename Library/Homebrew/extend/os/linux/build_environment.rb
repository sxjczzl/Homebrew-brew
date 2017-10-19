module Homebrew
  module_function

  def os_specific_build_env_keys
    %w[LD_LIBRARY_PATH LD_RUN_PATH LD_PRELOAD LIBRARY_PATH]
  end
end
