# frozen_string_literal: true

require 'json'

module RSpec
  ##
  # RSpec::FlakeySpec - An instance of an indeterminate spec.
  #
  class FlakeySpec
    attr_reader :messages, :attempts, :retry_count, :location

    def initialize(example, attempts, retry_count)
      @example = example
      @attempts = attempts
      @retry_count = retry_count
      @messages = RetryMessage.new(@example).exception_strings
      @location = @example.location
    end

    def as_json
      { attempts:, retry_count:, location:, messages: }
    end
  end
end
