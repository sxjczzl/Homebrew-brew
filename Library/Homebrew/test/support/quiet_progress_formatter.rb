require "rspec/core/formatters/progress_formatter"

class QuietProgressFormatter < RSpec::Core::Formatters::ProgressFormatter
  RSpec::Core::Formatters.register self, :seed

  def seed(notification); end

  def message(notification)
    if notification.message.start_with? "Run options: exclude"
      return
    end
    puts "MESSAGE: #{notification}"
  end
end
