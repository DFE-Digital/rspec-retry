# frozen_string_literal: true

require 'rspec/core'
require 'rspec/retry_configuration'
require 'rspec/retry_message'
require 'rspec/flakey_spec'
require 'rspec/retry/version'
require 'rspec_ext/rspec_ext'

module RSpec
  ##
  # RSpec::Retry - retry failed examples
  #
  class Retry
    attr_reader :context, :procsy, :retry_reporter_data

    def initialize(procsy, opts = {})
      @procsy = procsy
      @procsy.metadata.merge!(opts)
      current_example.attempts ||= 0
      @retry_reporter_data = []
    end

    def current_example
      @current_example ||= RSpec.current_example
    end

    def retry_count
      [(ENV['RSPEC_RETRY_RETRY_COUNT'] || procsy.metadata[:retry] ||
        config.retry_count_condition.call(procsy) || config.default_retry_count).to_i, 1].max
    end

    def attempts
      current_example.attempts ||= 0
    end

    def attempts=(val)
      current_example.attempts = val
    end

    def config
      RSpec.configuration
    end

    def retry_config
      RetryConfiguration.new(procsy)
    end

    def run
      example = current_example

      loop do
        report_repeat_attempt(example) if attempts.positive?

        reset_and_run_example(example)

        break if example.exception.nil? || skip_example?(example)

        example.metadata[:retry_exceptions] << example.exception

        handle_indeterminate_failures(example) if attempts.positive? && attempts < retry_count

        perform_after_retry_tasks(example)
      end

      report_on_flakey_examples if retry_reporter_data.any? && attempts < retry_count
    end

  private

    def reset_and_run_example(example)
      reset_example_metadata(example)

      procsy.run

      self.attempts += 1
    end

    # rubocop:disable Style/CaseEquality
    def exception_exists_in?(list, exception)
      list.any? { |exception_klass| exception.is_a?(exception_klass) || exception_klass === exception }
    end
    # rubocop:enable Style/CaseEquality

    def skip_example?(example)
      attempts_gte_retry_count? || exception_should_hard_fail?(example.exception) ||
        exception_should_not_be_retried?(example.exception)
    end

    def attempts_gte_retry_count?
      attempts >= retry_count
    end

    def exception_should_hard_fail?(exception)
      retry_config.exceptions_to_hard_fail.any? && exception_exists_in?(retry_config.exceptions_to_hard_fail, exception)
    end

    def exception_should_not_be_retried?(exception)
      retry_config.exceptions_to_retry.any? && !exception_exists_in?(retry_config.exceptions_to_retry, exception)
    end

    def reset_example_metadata(example)
      example.metadata[:retry_attempts] = attempts
      example.metadata[:retry_exceptions] ||= []

      example.clear_exception
    end

    def run_callbacks(example)
      return unless config.retry_callback

      example.example_group_instance.instance_exec(example, &config.retry_callback)
    end

    def report_on_flakey_examples
      config.retry_reporter&.message(retry_reporter_data.to_json)

      @retry_reporter_data = []
    end

    def report_repeat_attempt(example)
      config.formatters.each { |f| f.retry(example) if f.respond_to? :retry }
      send_retry_message_to_reporter(example) if config.verbose_retry?
    end

    def send_retry_message_to_reporter(example)
      config.reporter.message(RetryMessage.new(example).message_for_attempt(attempts))
    end

    def handle_indeterminate_failures(example)
      retry_reporter_data << FlakeySpec.new(example, attempts, retry_count).as_json
    end

    def perform_after_retry_tasks(example)
      example.example_group_instance.clear_lets if retry_config.clear_lets?

      run_callbacks(example)

      interval = retry_config.sleep_interval(attempts)
      sleep interval if interval.to_f.positive?
    end
  end
end

RSpec::RetryConfiguration.setup
