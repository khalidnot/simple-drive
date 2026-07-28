# app/services/storage/s3_signer.rb
require "cgi"
require "digest"
require "openssl"
require "uri"

module Storage
  class S3Signer
    ALGORITHM = "AWS4-HMAC-SHA256"
    SERVICE = "s3"

    def initialize(method:, endpoint:, bucket:, object_key:, region:, access_key_id:, secret_access_key:, body: "")
      @method = method.to_s.upcase
      @endpoint_uri = URI.parse(endpoint)
      @bucket = bucket.to_s
      @object_key = object_key.to_s
      @region = region.to_s
      @access_key_id = access_key_id.to_s
      @secret_access_key = secret_access_key.to_s
      @body = body.to_s.b
      @amz_date = Time.now.utc.strftime("%Y%m%dT%H%M%SZ")
      @date_stamp = @amz_date[0, 8]
    end

    def headers
      {
        "Host" => host_header,
        "x-amz-content-sha256" => payload_hash,
        "x-amz-date" => @amz_date,
        "Authorization" => authorization_header
      }
    end

    private

    def host_header
      if @endpoint_uri.port == @endpoint_uri.default_port
        @endpoint_uri.host
      else
        "#{@endpoint_uri.host}:#{@endpoint_uri.port}"
      end
    end

    def payload_hash
      Digest::SHA256.hexdigest(@body)
    end

    def canonical_uri
      "/#{@bucket}/#{canonical_object_key}"
    end

    def canonical_object_key
      return "" if @object_key.empty?

      @object_key.split("/").map { |segment| escape_path_segment(segment) }.join("/")
    end

    def canonical_query_string
      ""
    end

    def canonical_headers
      [
        "host:#{host_header}",
        "x-amz-content-sha256:#{payload_hash}",
        "x-amz-date:#{@amz_date}"
      ].join("\n") + "\n"
    end

    def signed_headers
      "host;x-amz-content-sha256;x-amz-date"
    end

    def canonical_request
      [
        @method,
        canonical_uri,
        canonical_query_string,
        canonical_headers,
        signed_headers,
        payload_hash
      ].join("\n")
    end

    def credential_scope
      "#{@date_stamp}/#{@region}/#{SERVICE}/aws4_request"
    end

    def string_to_sign
      [
        ALGORITHM,
        @amz_date,
        credential_scope,
        Digest::SHA256.hexdigest(canonical_request)
      ].join("\n")
    end

    def signing_key
      k_date = hmac("AWS4#{@secret_access_key}", @date_stamp)
      k_region = hmac(k_date, @region)
      k_service = hmac(k_region, SERVICE)
      hmac(k_service, "aws4_request")
    end

    def hmac(key, data)
      OpenSSL::HMAC.digest("sha256", key, data)
    end

    def signature
      OpenSSL::HMAC.hexdigest("sha256", signing_key, string_to_sign)
    end

    def authorization_header
      "#{ALGORITHM} Credential=#{@access_key_id}/#{credential_scope}, SignedHeaders=#{signed_headers}, Signature=#{signature}"
    end

    def escape_path_segment(segment)
      CGI.escape(segment.to_s).gsub("+", "%20").gsub("%7E", "~")
    end
  end
end