module Homebrew
  module Install
    module_function

    def perform_preinstall_checks(all_fatal: false)
      generic_perform_preinstall_checks(all_fatal: all_fatal)
    end
  end
end
