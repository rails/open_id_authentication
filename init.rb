begin
  require 'openid'
rescue LoadError
  begin
    gem 'ruby-openid', '>=2.0.4'
  rescue Gem::LoadError
    puts "Install the ruby-openid gem to enable OpenID support"
  end
end

ActionController::Base.send :include, OpenIdAuthentication
