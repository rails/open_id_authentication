require 'test/unit'

require 'rubygems'
gem 'mocha'
require 'mocha'

gem 'ruby-openid'
require 'openid'

RAILS_ROOT = File.dirname(__FILE__)
require File.dirname(__FILE__) + "/../lib/open_id_authentication"

class OpenIdAuthenticationTest < Test::Unit::TestCase
  def setup
    @controller = Class.new do
      include OpenIdAuthentication
      def params() {} end
    end.new
  end

  def test_authentication_should_fail_when_the_identity_server_is_missing
    @controller.stubs(:open_id_consumer).returns(stub(:begin => stub(:status => OpenID::FAILURE)))
    
    @controller.send(:authenticate_with_open_id, "http://someone.example.com") do |result, identity_url|
      assert result.missing?
      assert_equal "Sorry, the OpenID server couldn't be found", result.message
    end
  end

  def test_authentication_should_fail_when_the_identity_server_times_out
    @controller.stubs(:open_id_consumer).returns(stub(:begin => Proc.new { raise Timeout::Error, "Identity Server took too long." }))

    @controller.send(:authenticate_with_open_id, "http://someone.example.com") do |result, identity_url|
      assert result.missing?
      assert_equal "Sorry, the OpenID server couldn't be found", result.message
    end
  end

  def test_authentication_should_begin_when_the_identity_server_is_present
    @controller.stubs(:open_id_consumer).returns(stub(:begin => stub(:status => OpenID::SUCCESS)))
    @controller.expects(:begin_open_id_authentication) 
    @controller.send(:authenticate_with_open_id, "http://someone.example.com")
  end
end