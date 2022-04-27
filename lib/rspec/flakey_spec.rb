# frozen_string_literal: true

require 'json'

module RSpec
  ##
  # An instance of an indeterminate spec.
  #
  class FlakeySpec
    def initialize(attempts, retry_count, location, messages)
      @attempts = attempts
      @retry_count = retry_count
      @location = location
      @messages = messages
    end

    def to_h
      { attempts: @attempts, retry_count: @retry_count, location: @location, messages: @messages }
    end

    def to_json(_)
      to_h.to_json
    end
  end
end
