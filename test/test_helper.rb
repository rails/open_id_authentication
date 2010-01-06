RAILS_ROOT = File.dirname(__FILE__) unless defined? RAILS_ROOT

require 'test/unit'
require 'mocha'

require 'active_support'
require 'active_record'
require 'action_controller'
require 'initializer' # for Rails.root

require 'open_id_authentication'
