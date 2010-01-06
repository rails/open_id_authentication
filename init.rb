if Rails.version < '3'
  config.gem 'ruby-openid', :lib => 'openid', :version => '>=2.0.4'
end

begin
  require 'openid'
rescue LoadError
  abort "Install the ruby-openid gem to enable OpenID support"
end

ActionController::Dispatcher.to_prepare do
  OpenID::Util.logger = Rails.logger
  ActionController::Base.send :include, OpenIdAuthentication
end
