# frozen_string_literal: true

module RSpec
  ##
  # RSpec::RetryMessage - Handles exception messaging for retried Rspec examples
  #
  class RetryMessage
    attr_reader :example, :exception

    def initialize(example)
      @example = example
      @exception = example.exception
    end

    def exception_strings
      if exception.is_a?(::RSpec::Core::MultipleExceptionError::InterfaceTag)
        exception.all_exceptions.map(&:to_s)
      else
        [exception.to_s]
      end
    end

    def inline_exception_strings
      exception_strings.map { |s| s.gsub(/[\n\r\s]+/, ' ').strip }
    end

    def try_message(attempts)
      [
        "\n#{ordinalize(attempts)} Try error in #{example.location}:",
        "#{exception_strings.join("\n")}\n",
      ].join("\n")
    end

    def message_for_attempt(attempts)
      message = "RSpec::Retry: #{ordinalize(attempts + 1)} try #{example.location}"
      message = "\n#{message}" if attempts == 1
      message
    end

    # borrowed from ActiveSupport::Inflector
    def ordinalize(number)
      if (11..13).include?(number.to_i % 100)
        "#{number}th"
      else
        case number.to_i % 10
        when 1 then "#{number}st"
        when 2 then "#{number}nd"
        when 3 then "#{number}rd"
        else "#{number}th"
        end
      end
    end
  end
end
