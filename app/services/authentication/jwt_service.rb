# app/services/authentication/jwt_service.rb
module Authentication
  class JwtService
    SECRET = Rails.application.secret_key_base

    def self.encode(payload, exp = 30.minutes.from_now)
      payload[:exp] = exp.to_i
      JWT.encode(payload, SECRET, "HS256")
    end

    def self.decode(token)
      decoded = JWT.decode(token, SECRET, true, algorithm: "HS256")[0]
      HashWithIndifferentAccess.new(decoded)
    end
  end
end