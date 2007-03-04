module OpenIdAuthentication
  OPEN_ID_AUTHENTICATION_DIR = RAILS_ROOT + "/tmp/openids"

  class Result
    MESSAGES = {
      :missing    => "Sorry, the OpenID server couldn't be found",
      :canceled   => "OpenID verification was canceled",
      :failed     => "Sorry, the OpenID verification failed",
      :successful => "OpenID authentication successful"
    }
    
    ERROR_STATES = [ :missing, :canceled, :failed ]
    
    def self.[](code)
      new(code)
    end
    
    def initialize(code)
      @code = code
    end
    
    def ===(code)
      if code == :unsuccessful && unsuccessful?
        true
      else
        @code == code
      end
    end
    
    MESSAGES.keys.each { |state| define_method("#{state}?") { @code == state } }

    def unsuccessful?
      ERROR_STATES.include?(@code)
    end
    
    def message
      MESSAGES[@code]
    end
  end


  protected
    # OpenIDs are expected to begin with http:// or https://
    def open_id?(user_name) #:doc:
      (Object.const_defined?(:OpenID) && user_name =~ /^https?:\/\//i) || params[:open_id_complete]
    end

    def authenticate_with_open_id(identity_url, fields = {}, &block) #:doc:
      if params[:open_id_complete].nil?
        begin_open_id_authentication(identity_url, fields, &block)
      else
        complete_open_id_authentication(&block)
      end
    end

  private
    def begin_open_id_authentication(identity_url, fields = {})
      open_id_response = timeout_protection_from_identity_server { open_id_consumer.begin(identity_url) }

      case open_id_response.status
      when OpenID::FAILURE
        yield Result[:missing], identity_url, nil
      when OpenID::SUCCESS
        add_simple_registration_fields(open_id_response, fields)
        redirect_to(open_id_redirect_url(open_id_response))
      end
    end
  
    def complete_open_id_authentication
      open_id_response = timeout_protection_from_identity_server { open_id_consumer.complete(params) }

      case open_id_response.status
      when OpenID::CANCEL
        yield Result[:canceled], open_id_response.identity_url, nil
      when OpenID::FAILURE
        logger.info "OpenID authentication failed: #{open_id_response.msg}"
        yield Result[:failed], open_id_response.identity_url, nil
      when OpenID::SUCCESS
        yield Result[:successful], open_id_response.identity_url, open_id_response.extension_response('sreg')
      end      
    end

    def open_id_consumer
      OpenID::Consumer.new(session, OpenID::FilesystemStore.new(OPEN_ID_AUTHENTICATION_DIR))
    end


    def add_simple_registration_fields(open_id_response, fields)
      open_id_response.add_extension_arg('sreg', 'required', [ fields[:required] ].flatten * ',') if fields[:required]
      open_id_response.add_extension_arg('sreg', 'optional', [ fields[:optional] ].flatten * ',') if fields[:optional]
    end
    
    def open_id_redirect_url(open_id_response)
      open_id_response.redirect_url(
        request.protocol + request.host,
        open_id_response.return_to("#{request.url}?open_id_complete=1")
      )     
    end


    def timeout_protection_from_identity_server
      yield
    rescue Timeout::Error
      Class.new do
        def status
          OpenID::FAILURE
        end
        
        def msg
          "Identity server timed out"
        end
      end.new
    end
end