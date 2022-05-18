# frozen_string_literal: true

require 'json'

module RSpec
  ##
  # RSpec::FlakeySpec - An instance of an indeterminate spec.
  #
  class FlakeySpec
    attr_reader :messages

    def initialize(example, attempts, retry_count)
      @example = example
      @attempts = attempts
      @retry_count = retry_count
      @messages = RetryMessage.new(@example).exception_strings
    end

    def as_json
      { attempts: @attempts, retry_count: @retry_count, location: @example.location, messages: messages }
    end
  end
end
