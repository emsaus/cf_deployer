require 'spec_helper'
require 'webmock/rspec'
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = "fixtures/vcr_cassettes"
  config.hook_into :webmock
end

def override_aws_environment options = {}
  options[:AWS_REGION] ||= 'us-east-1'
  options[:AWS_ACCESS_KEY_ID] ||= 'someId'
  options[:AWS_SECRET_ACCESS_KEY] ||= 'secretKey'
  options[:AWS_EC2_METADATA_DISABLED] ||= 'true'
  options[:AWS_SDK_CONFIG_OPT_OUT] ||= '1'

  override_environment_variables(options) do
    previous_aws_config = Aws.config.dup
    Aws.config.update(
      region: options[:AWS_REGION],
      credentials: Aws::Credentials.new(options[:AWS_ACCESS_KEY_ID], options[:AWS_SECRET_ACCESS_KEY])
    )
    yield
  ensure
    Aws.config.clear
    Aws.config.update(previous_aws_config)
  end
end

def override_environment_variables options = {}
  previous_values = override_previous_values(options)

  yield

  restore_values(previous_values)
end

def override_previous_values options = {}
  previous_values = options.inject([]) do |memo, (key,value)|
    memo << { key: key.to_s, value: value, existed: ENV.has_key?(key.to_s), old_value: ENV[key.to_s] }
    ENV[key.to_s] = value
    memo
  end
end

def restore_values previous_values = []
  previous_values.each do |value|
    value[:existed] ? ENV[value[:key]] = value[:old_value] : ENV.delete(value[:key])
  end
end
