module OpenIdAuthentication
  OPEN_ID_AUTHENTICATION_DIR = RAILS_ROOT + "/tmp/openids"

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
      open_id_response = open_id_consumer.begin(identity_url)

      case open_id_response.status
      when OpenID::FAILURE
        yield :missing, identity_url, nil
      when OpenID::SUCCESS
        add_simple_registration_fields(open_id_response, fields)
        redirect_to(open_id_redirect_url(open_id_response))
      end
    end
  
    def complete_open_id_authentication
      open_id_response = open_id_consumer.complete(params)

      case open_id_response.status
      when OpenID::CANCEL
        yield :canceled, open_id_response.identity_url, nil
      when OpenID::FAILURE
        logger.info "OpenID authentication failed: #{open_id_response.msg}"
        yield :failed, open_id_response.identity_url, nil
      when OpenID::SUCCESS
        yield :successful, open_id_response.identity_url, open_id_response.extension_response('sreg')
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
end