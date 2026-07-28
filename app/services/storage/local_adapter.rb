# app/services/storage/local_adapter.rb
require "fileutils"

module Storage
  class LocalAdapter < BaseAdapter
    def save(blob:, data:)
      FileUtils.mkdir_p(storage_directory)
      File.binwrite(file_path(blob), data)
    end

    def fetch(blob:)
      File.binread(file_path(blob))
    end

    private

    def storage_directory
      ENV.fetch("STORAGE_PATH", Rails.root.join("storage", "blobs").to_s)
    end

    def file_path(blob)
      File.join(storage_directory, blob.blob_id.to_s)
    end
  end
end