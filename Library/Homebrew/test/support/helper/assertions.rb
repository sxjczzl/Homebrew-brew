module Test
  module Helper
    module Assertions
      def assert_nothing_raised
        yield
      end

      def assert_eql(exp, act, msg = nil)
        msg = message(msg, "") { diff exp, act }
        assert exp.eql?(act), msg
      end

      def refute_eql(exp, act, msg = nil)
        msg = message(msg) do
          "Expected #{mu_pp(act)} to not be eql to #{mu_pp(exp)}"
        end
        refute exp.eql?(act), msg
      end
    end
  end
end
