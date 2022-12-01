# frozen_string_literal: true

require 'rspec/core'

module RSpec
  # RSpec::RetryConfiguration - Enables rspec-retry specific configuration settings
  class RetryConfiguration
    def self.setup
      RSpec.configure do |config|
        config.add_setting :verbose_retry, default: false
        config.add_setting :default_retry_count, default: 1
        config.add_setting :default_sleep_interval, default: 0
        config.add_setting :exponential_backoff, default: false
        config.add_setting :clear_lets_on_failure, default: true
        config.add_setting :display_try_failure_messages, default: false
        config.add_setting :retry_reporter
        config.add_setting :source_code_repo_url

        # retry based on example metadata
        config.add_setting :retry_count_condition, default: ->(_) {}

        # If a list of exceptions is provided and 'retry' > 1, we only retry if
        # the exception that was raised by the example is NOT in that list. Otherwise
        # we ignore the 'retry' value and fail immediately.
        #
        # If no list of exceptions is provided and 'retry' > 1, we always retry.
        config.add_setting :exceptions_to_hard_fail, default: []

        # If a list of exceptions is provided and 'retry' > 1, we only retry if
        # the exception that was raised by the example is in that list. Otherwise
        # we ignore the 'retry' value and fail immediately.
        #
        # If no list of exceptions is provided and 'retry' > 1, we always retry.
        config.add_setting :exceptions_to_retry, default: []

        # Callback between retries
        config.add_setting :retry_callback, default: nil

        config.around(:each, &:run_with_retry)
      end
    end

    attr_reader :procsy

    def initialize(procsy)
      @procsy = procsy
    end

    def exceptions_to_hard_fail
      procsy.metadata[:exceptions_to_hard_fail] || RSpec.configuration.exceptions_to_hard_fail
    end

    def exceptions_to_retry
      procsy.metadata[:exceptions_to_retry] || RSpec.configuration.exceptions_to_retry
    end

    def clear_lets?
      if procsy.metadata[:clear_lets_on_failure].nil?
        RSpec.configuration.clear_lets_on_failure
      else
        procsy.metadata[:clear_lets_on_failure]
      end
    end

    def sleep_interval(attempts)
      if procsy.metadata[:exponential_backoff]
        (2**(attempts - 1)) * procsy.metadata[:retry_wait]
      else
        procsy.metadata[:retry_wait] || RSpec.configuration.default_sleep_interval
      end
    end
  end
end
