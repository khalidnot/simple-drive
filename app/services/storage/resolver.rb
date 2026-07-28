# app/services/storage/resolver.rb
module Storage
  class Resolver
    def self.call(backend = ENV.fetch("STORAGE_BACKEND", "local"))
      case backend
      when "local"
        LocalAdapter.new
      when "database"
        DatabaseAdapter.new
      when "s3"
        S3Adapter.new
      else
        raise "Unsupported storage backend"
      end
    end
  end
end