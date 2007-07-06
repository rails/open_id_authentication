require 'test/unit'
require 'rubygems'
require 'active_support'

RAILS_ROOT = File.dirname(__FILE__)
require File.dirname(__FILE__) + "/../lib/open_id_authentication"

class NormalizeTest < Test::Unit::TestCase
  include OpenIdAuthentication

  NORMALIZATIONS = {
    "openid.aol.com/nextangler"         => "http://openid.aol.com/nextangler",
    "http://openid.aol.com/nextangler"  => "http://openid.aol.com/nextangler",
    "https://openid.aol.com/nextangler" => "https://openid.aol.com/nextangler",
    "loudthinking.com"                  => "http://loudthinking.com/",
    "http://loudthinking.com"           => "http://loudthinking.com/",
    "techno-weenie.net"                 => "http://techno-weenie.net/",
    "http://techno-weenie.net"          => "http://techno-weenie.net/"
  }

  def test_normalizations
    NORMALIZATIONS.each do |from, to|
      assert_equal to, normalize_url(from)
    end
  end
  
  def test_broken_open_id
    assert_raises(InvalidOpenId) { normalize_url("=name") }
  end
end