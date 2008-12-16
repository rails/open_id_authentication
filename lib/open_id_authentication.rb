require 'uri'
require 'openid/store/filesystem'

require File.dirname(__FILE__) + '/../vendor/rack-openid/lib/rack/openid'
require File.dirname(__FILE__) + '/open_id_authentication/db_store'
require File.dirname(__FILE__) + '/open_id_authentication/mem_cache_store'
require File.dirname(__FILE__) + '/open_id_authentication/timeout_fixes' if OpenID::VERSION == "2.0.4"

module OpenIdAuthentication
  def self.new(app)
    ::Rack::OpenID.new(app, OpenIdAuthentication.store)
  end

  OPEN_ID_AUTHENTICATION_DIR = RAILS_ROOT + "/tmp/openids" if defined? RAILS_ROOT

  def self.store
    @@store
  end

  def self.store=(*store_option)
    store, *parameters = *([ store_option ].flatten)

    @@store = case store
    when :db
      OpenIdAuthentication::DbStore.new
    when :mem_cache
      OpenIdAuthentication::MemCacheStore.new(*parameters)
    when :file
      OpenID::Store::Filesystem.new(OPEN_ID_AUTHENTICATION_DIR)
    else
      raise "Unknown store: #{store}"
    end
  end

  self.store = :db

  class Result
    ERROR_MESSAGES = {
      :missing      => "Sorry, the OpenID server couldn't be found",
      :invalid      => "Sorry, but this does not appear to be a valid OpenID",
      :canceled     => "OpenID verification was canceled",
      :failed       => "OpenID verification failed",
      :setup_needed => "OpenID verification needs setup"
    }

    def self.[](code)
      new(code)
    end

    def initialize(code)
      @code = code
    end

    def status
      @code
    end

    ERROR_MESSAGES.keys.each { |state| define_method("#{state}?") { @code == state } }

    def successful?
      @code == :successful
    end

    def unsuccessful?
      ERROR_MESSAGES.keys.include?(@code)
    end

    def message
      ERROR_MESSAGES[@code]
    end
  end

  protected
    # The parameter name of "openid_identifier" is used rather than
    # the Rails convention "open_id_identifier" because that's what
    # the specification dictates in order to get browser auto-complete
    # working across sites
    def using_open_id?(identifier = nil) #:doc:
      identifier ||= open_id_identifier
      !identifier.blank?
    end

    def authenticate_with_open_id(identifier = nil, options = {}, &block) #:doc:
      identifier ||= open_id_identifier

      if request.env[Rack::OpenID::RESPONSE]
        complete_open_id_authentication(&block)
      else
        begin_open_id_authentication(identifier, options, &block)
      end
    end

  private
    def open_id_identifier
      params[:openid_identifier] || params[:openid_url]
    end

    def begin_open_id_authentication(identifier, options = {})
      options[:identifier] = identifier
      value = Rack::OpenID.build_header(options)
      response.headers[Rack::OpenID::AUTHENTICATE_HEADER] = value
      head :unauthorized
    end

    def complete_open_id_authentication
      response   = request.env[Rack::OpenID::RESPONSE]
      identifier = response.display_identifier

      case response.status
      when OpenID::Consumer::SUCCESS
        yield Result[:successful], identifier,
          OpenID::SReg::Response.from_success_response(response)
      when :missing
        yield Result[:missing], identifier, nil
      when :invalid
        yield Result[:invalid], identifier, nil
      when OpenID::Consumer::CANCEL
        yield Result[:canceled], identifier, nil
      when OpenID::Consumer::FAILURE
        yield Result[:failed], identifier, nil
      when OpenID::Consumer::SETUP_NEEDED
        yield Result[:setup_needed], response.setup_url, nil
      end
    end
end
