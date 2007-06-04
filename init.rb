begin
  require 'openid'  
rescue LoadError
  begin
    gem 'ruby-openid'
    require 'openid'
  rescue LoadError
    puts "Install the ruby-openid gem to enable OpenID support"
  end
end

ActionController::Base.send :include, OpenIdAuthentication