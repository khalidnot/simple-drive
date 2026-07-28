module Storage
  class DatabaseAdapter < BaseAdapter
    def save(blob:, data:)
      blob_content = blob.blob_content || blob.build_blob_content
      blob_content.data = data
      blob_content.save!
    end

    def fetch(blob:)
      blob.blob_content&.data || raise(ActiveRecord::RecordNotFound, "Blob content not found for #{blob.blob_id}")
    end
  end
end