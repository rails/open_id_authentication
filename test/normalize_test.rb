require 'test/unit'

RAILS_ROOT = File.dirname(__FILE__)
require File.dirname(__FILE__) + "/../lib/open_id_authentication"

class NormalizeTest < Test::Unit::TestCase
  include OpenIdAuthentication

  NORMALIZATIONS = {
    "openid.aol.com/nextangler"         => "http://openid.aol.com/nextangler",
    "http://openid.aol.com/nextangler"  => "http://openid.aol.com/nextangler",
    "https://openid.aol.com/nextangler" => "https://openid.aol.com/nextangler",
    "loudthinking.com"                  => "http://loudthinking.com/",
    "http://loudthinking.com"           => "http://loudthinking.com/"
  }

  def test_normalizations
    NORMALIZATIONS.each do |from, to|
      assert_equal to, normalize_url(from)
    end
  end
end