module Homebrew
  module Diagnostic
    class Checks
      def check_integration_test
        "This is an integration test" if ENV["HOMEBREW_INTEGRATION_TEST"]
      end
    end
  end

  def exec(*args)
    # Ensure we retain coverage results before replacing the current process.
    Homebrew::CoverageHelper.save_coverage
    Kernel.exec(*args)
  end
end
