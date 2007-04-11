namespace :open_id_authentication do
  namespace :db do
    desc "Creates authentication tables for use with OpenIdAuthentication"
    task :create => :environment do
      raise "Task unavailable to this database (no migration support)" unless ActiveRecord::Base.connection.supports_migrations?
      require 'rails_generator'
      require 'rails_generator/scripts/generate'
      Rails::Generator::Scripts::Generate.new.run([ "open_id_authentication_tables", "add_open_id_authentication_tables" ])
    end

    desc "Clear the authentication tables"
    task :clear => :environment do
      OpenIdAuthentication::DbStore.gc
    end
  end
end