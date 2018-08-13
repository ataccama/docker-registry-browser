class Resource
  private

  def self.client
    @client ||= begin
      options = { 
        url: Rails.configuration.x.registry_url,
        ssl: {
          verify: !Rails.configuration.x.no_ssl_verification
        }
      }
      
      unless (
        Rails.configuration.x.ssl_ca_path.nil? or
        Rails.configuration.x.ssl_cert_path.nil? or
        Rails.configuration.x.ssl_key_path.nil?
      )
        options[:ssl].merge!({
           ca_file: Rails.configuration.x.ssl_ca_path,
           client_cert: OpenSSL::X509::Certificate.new(File.read(Rails.configuration.x.ssl_cert_path)),
           client_key: OpenSSL::PKey::RSA.new(File.read(Rails.configuration.x.ssl_key_path), nil),
        })
      end

      Faraday.new(options) do |f|
        if Rails.configuration.x.basic_auth_user && Rails.configuration.x.basic_auth_password
          f.use Faraday::Request::BasicAuthentication,
            Rails.configuration.x.basic_auth_user,
            Rails.configuration.x.basic_auth_password
        end
        f.use FaradayMiddleware::ParseJson, content_type: /json|prettyjws/
        f.response :logger unless Rails.env.test?
        f.response :raise_error
        f.adapter  Faraday.default_adapter
      end
    end
  end

  def client
    self.class.client
  end
end
