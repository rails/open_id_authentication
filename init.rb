begin
  gem 'ruby-openid', '=1.1.4'
  require 'openid'  
rescue LoadError
  puts "Install the ruby-openid gem to enable OpenID support"
end

ActionController::Base.send :include, OpenIdAuthentication