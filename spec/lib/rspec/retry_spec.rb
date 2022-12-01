# frozen_string_literal: true

require 'spec_helper'

class RetryError < StandardError; end

class RetryChildError < RetryError; end

class HardFailError < StandardError; end

class HardFailChildError < HardFailError; end

class OtherError < StandardError; end

class SharedError < StandardError; end

class RetryExampleGroup
  class << self
    attr_accessor :count, :fail, :results
  end
end

describe RSpec::Retry do
  def count
    @count ||= 0
    @count
  end

  def count_up
    @count ||= 0
    @count += 1
  end

  def set_expectations(expectations)
    @expectations = expectations
  end

  def shift_expectation
    @expectations.shift
  end

  before(:all) do
    ENV.delete('RSPEC_RETRY_RETRY_COUNT')
  end

  context 'no retry option' do
    it 'should work' do
      expect(true).to be(true)
    end
  end

  context 'with retry option' do
    before(:each) { count_up }

    context do
      before(:all) { set_expectations([false, false, true]) }

      it 'should run example until :retry times', retry: 3 do
        expect(true).to be(shift_expectation)
        expect(count).to eq(3)
      end
    end

    context do
      before(:all) { set_expectations([false, true, false]) }

      it 'should stop retrying if  example is succeeded', retry: 3 do
        expect(true).to be(shift_expectation)
        expect(count).to eq(2)
      end
    end

    context 'with lambda condition' do
      before(:all) { set_expectations([false, true]) }

      it 'should get retry count from condition call', retry_me_once: true do
        expect(true).to be(shift_expectation)
        expect(count).to eq(2)
      end
    end

    context 'with :retry => 0' do
      before(:all) { RetryExampleGroup.count = 0 }
      after(:all) { RetryExampleGroup.count = 0 }

      it 'should still run once', retry: 0 do
        RetryExampleGroup.count += 1
      end

      it 'should run have run once' do
        expect(RetryExampleGroup.count).to be 1
      end
    end

    context 'with the environment variable RSPEC_RETRY_RETRY_COUNT' do
      before(:all) do
        set_expectations([false, false, true])
        ENV['RSPEC_RETRY_RETRY_COUNT'] = '3'
      end

      after(:all) do
        ENV.delete('RSPEC_RETRY_RETRY_COUNT')
      end

      it 'should override the retry count set in an example', retry: 2 do
        expect(true).to be(shift_expectation)
        expect(count).to eq(3)
      end
    end

    context 'with exponential backoff enabled', retry: 3, retry_wait: 0.001, exponential_backoff: true do
      context do
        before(:all) do
          set_expectations([false, false, true])
          @start_time = Time.now
        end

        it 'should run example until :retry times', retry: 3 do
          expect(true).to be(shift_expectation)
          expect(count).to eq(3)
          expect(Time.now - @start_time).to be >= (0.001)
        end
      end
    end

    describe 'with a list of exceptions to immediately fail on', retry: 2,
                                                                 exceptions_to_hard_fail: [HardFailError] do
      context 'the example throws an exception contained in the hard fail list' do
        it 'does not retry' do
          expect(count).to be < 2
          pending "This should fail with a count of 1: Count was #{count}"
          raise HardFailError unless count > 1
        end
      end

      context 'the example throws a child of an exception contained in the hard fail list' do
        it 'does not retry' do
          expect(count).to be < 2
          pending "This should fail with a count of 1: Count was #{count}"
          raise HardFailChildError unless count > 1
        end
      end

      context 'the throws an exception not contained in the hard fail list' do
        it 'retries the maximum number of times' do
          raise OtherError unless count > 1

          expect(count).to eq(2)
        end
      end
    end

    describe 'with a list of exceptions to retry on', retry: 2, exceptions_to_retry: [RetryError] do
      context do
        let(:rspec_version) { RSpec::Core::Version::STRING }

        let(:example_code) do
          %(
            $count ||= 0
            $count += 1

            raise NameError unless $count > 2
          )
        end

        let!(:example_group) do
          $count = 0
          $example_code = example_code

          RSpec.describe('example group', exceptions_to_retry: [NameError], retry: 3).tap(&:run)
        end

        let(:retry_attempts) do
          example_group.examples.first.metadata[:retry_attempts]
        end

        it 'should retry and match attempts metadata' do
          example_group.example { instance_eval($example_code) }
          example_group.run

          expect(retry_attempts).to eq(2)
        end

        let(:retry_exceptions) do
          example_group.examples.first.metadata[:retry_exceptions]
        end

        it 'should add exceptions into retry_exceptions metadata array' do
          example_group.example { instance_eval($example_code) }
          example_group.run

          expect(retry_exceptions.count).to eq(2)
          expect(retry_exceptions[0].class).to eq NameError
          expect(retry_exceptions[1].class).to eq NameError
        end
      end

      context 'the example throws an exception contained in the retry list' do
        it 'retries the maximum number of times' do
          raise RetryError unless count > 1

          expect(count).to eq(2)
        end
      end

      context 'the example throws a child of an exception contained in the retry list' do
        it 'retries the maximum number of times' do
          raise RetryChildError unless count > 1

          expect(count).to eq(2)
        end
      end

      context 'the example fails (with an exception not in the retry list)' do
        it 'only runs once' do
          set_expectations([false])
          expect(count).to eq(1)
        end
      end

      context 'the example retries exceptions which match with case equality' do
        class CaseEqualityError < StandardError
          def self.===(other)
            # An example of dynamic matching
            other.message == 'Rescue me!'
          end
        end

        it 'retries the maximum number of times', exceptions_to_retry: [CaseEqualityError] do
          raise StandardError, 'Rescue me!' unless count > 1

          expect(count).to eq(2)
        end
      end
    end

    describe 'with both hard fail and retry list of exceptions', retry: 2,
                                                                 exceptions_to_retry: [SharedError, RetryError], exceptions_to_hard_fail: [SharedError, HardFailError] do
      context 'the exception thrown exists in both lists' do
        it 'does not retry because the hard fail list takes precedence' do
          expect(count).to be < 2
          pending "This should fail with a count of 1: Count was #{count}"
          raise SharedError unless count > 1
        end
      end

      context 'the example throws an exception contained in the hard fail list' do
        it 'does not retry because the hard fail list takes precedence' do
          expect(count).to be < 2
          pending "This should fail with a count of 1: Count was #{count}"
          raise HardFailError unless count > 1
        end
      end

      context 'the example throws an exception contained in the retry list' do
        it "retries the maximum number of times because the hard fail list doesn't affect this exception" do
          raise RetryError unless count > 1

          expect(count).to eq(2)
        end
      end

      context 'the example throws an exception contained in neither list' do
        it 'does not retry because the the exception is not in the retry list' do
          expect(count).to be < 2
          pending "This should fail with a count of 1: Count was #{count}"
          raise OtherError unless count > 1
        end
      end
    end
  end

  describe 'clearing lets' do
    before(:all) do
      @control = true
    end

    let(:let_based_on_control) { @control }

    after do
      @control = false
    end

    it 'should clear the let when the test fails so it can be reset', retry: 2 do
      expect(let_based_on_control).to be(false)
    end

    it 'should not clear the let when the test fails', retry: 2, clear_lets_on_failure: false do
      expect(let_based_on_control).to be(!@control)
    end
  end

  describe 'running example.run_with_retry in an around filter', retry: 2 do
    before(:each) { count_up }
    before(:all) do
      set_expectations([false, false, true])
    end

    it 'allows retry options to be overridden', :overridden do
      expect(RSpec.current_example.metadata[:retry]).to eq(3)
    end

    it 'uses the overridden options', :overridden do
      expect(true).to be(shift_expectation)
      expect(count).to eq(3)
    end
  end

  describe 'calling retry_callback between retries', retry: 2 do
    before(:all) do
      RSpec.configuration.retry_callback = proc do |example|
        @retry_callback_called = true
        @example = example
      end
    end

    after(:all) do
      RSpec.configuration.retry_callback = nil
    end

    context 'if failure' do
      before(:all) do
        @retry_callback_called = false
        @example = nil
        @retry_attempts = 0
      end

      it 'should call retry callback', with_some: 'metadata' do |example|
        if @retry_attempts == 0
          @retry_attempts += 1
          expect(@retry_callback_called).to be(false)
          expect(@example).to eq(nil)
          raise "let's retry once!"
        elsif @retry_attempts > 0
          expect(@retry_callback_called).to be(true)
          expect(@example).to eq(example)
          expect(@example.metadata[:with_some]).to eq('metadata')
        end
      end
    end

    context 'does not call retry_callback if no errors' do
      before(:all) do
        @retry_callback_called = false
        @example = nil
      end

      after do
        expect(@retry_callback_called).to be(false)
        expect(@example).to be_nil
      end

      it { true }
    end
  end

  describe 'Example::Procsy#attempts' do
    let!(:example_group) do
      RSpec.describe do
        before :all do
          RetryExampleGroup.results = {}
        end

        around do |example|
          example.run_with_retry
          RetryExampleGroup.results[example.description] = [example.exception.nil?, example.attempts]
        end

        specify 'without retry option' do
          expect(true).to be(true)
        end

        specify 'with retry option', retry: 3 do
          expect(true).to be(false)
        end
      end
    end

    it 'should be exposed' do
      example_group.run
      expect(RetryExampleGroup.results).to eq(
        {
          'without retry option' => [true, 1],
          'with retry option' => [false, 3],
        }
      )
    end
  end

  describe 'indeterminate tests' do
    # rubocop:disable Style/ClassVars
    let!(:group) do
      RSpec.describe 'Indeterminate group', retry: 3 do
        RetryExampleGroup.fail = true

        after do
          RetryExampleGroup.fail = false
        end

        let(:error_message) do
          <<-ERR
            broken
            indeterminate
            spec
          ERR
        end

        it 'fails or passes' do
          raise error_message if RetryExampleGroup.fail

          true
        end
      end
    end
    # rubocop:enable Style/ClassVars

    it 'reports indeterminate tests correctly' do
      retry_output = StringIO.new
      reporter = RSpec::Core::Reporter.new(RSpec.configuration)
      reporter.register_listener(RSpec::Core::Formatters::BaseTextFormatter.new(retry_output), 'message')
      RSpec.configuration.retry_reporter = reporter

      group.run RSpec.configuration.retry_reporter

      parsed_json = JSON.parse(retry_output.string)
      expect(parsed_json.size).to eq(1)

      error_hash = parsed_json.first
      expect(error_hash['attempts']).to eq(1)
      expect(error_hash['retry_count']).to eq(3)
      expect(error_hash['location']).to match(%r{^./spec/lib/rspec/retry_spec.rb:\d+$})
      expect(error_hash['messages'].map { |m| m.gsub(/\s+/, ' ').strip }).to eq(['broken indeterminate spec'])
    end
  end
end
