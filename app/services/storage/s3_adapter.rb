# app/services/storage/s3_adapter.rb
require "cgi"
require "net/http"
require "uri"

module Storage
  class S3Adapter < BaseAdapter
    def save(blob:, data:)
      uri = object_uri(blob.blob_id)
      request = Net::HTTP::Put.new(uri.request_uri)
      request["Content-Type"] = "application/octet-stream"

      sign_request!(
        request,
        method: :put,
        object_key: blob.blob_id,
        body: data
      )

      request.body = data
      response = perform_request(uri, request)

      ensure_success!(response, [Net::HTTPSuccess, Net::HTTPCreated, Net::HTTPNoContent])
      true
    end

    def fetch(blob:)
      uri = object_uri(blob.blob_id)
      request = Net::HTTP::Get.new(uri.request_uri)

      sign_request!(
        request,
        method: :get,
        object_key: blob.blob_id,
        body: ""
      )

      response = perform_request(uri, request)
      ensure_success!(response, [Net::HTTPSuccess])

      response.body.to_s.b
    end

    private

    def endpoint
      ENV.fetch("S3_ENDPOINT")
    end

    def bucket
      ENV.fetch("S3_BUCKET")
    end

    def region
      ENV.fetch("S3_REGION", "us-east-1")
    end

    def access_key_id
      ENV.fetch("S3_ACCESS_KEY_ID")
    end

    def secret_access_key
      ENV.fetch("S3_SECRET_ACCESS_KEY")
    end

    def object_uri(object_key)
      uri = URI.parse(endpoint)
      uri.path = object_path(object_key)
      uri
    end

    def object_path(object_key)
      encoded_key = object_key.to_s.split("/").map { |segment| escape_path_segment(segment) }.join("/")
      "/#{bucket}/#{encoded_key}"
    end

    def escape_path_segment(segment)
      CGI.escape(segment.to_s).gsub("+", "%20").gsub("%7E", "~")
    end

    def sign_request!(request, method:, object_key:, body:)
      signer = S3Signer.new(
        method: method,
        endpoint: endpoint,
        bucket: bucket,
        object_key: object_key,
        region: region,
        access_key_id: access_key_id,
        secret_access_key: secret_access_key,
        body: body
      )

      signer.headers.each do |key, value|
        request[key] = value
      end
    end

    def perform_request(uri, request)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end
    end

    def ensure_success!(response, expected_classes)
      return if expected_classes.any? { |klass| response.is_a?(klass) }

      raise StandardError, "S3 request failed: #{response.code} #{response.message} - #{response.body}"
    end
  end
end