if Rails.version < '3'
  config.gem 'rack-openid', :lib => 'rack/openid', :version => '=>0.2.1'
  config.gem 'ruby-openid', :lib => 'openid', :version => '>=2.1.7'
end

config.middleware.use OpenIdAuthentication

ActionController::Dispatcher.to_prepare do
  OpenID::Util.logger = Rails.logger
  ActionController::Base.send :include, OpenIdAuthentication
end
