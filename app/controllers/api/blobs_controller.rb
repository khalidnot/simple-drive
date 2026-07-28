# app/controllers/v1/blobs_controller.rb
require "base64"

module Api
  class BlobsController < ApplicationController
    def create
      blob_id = blob_params[:id]
      encoded_data = blob_params[:data]

      if blob_id.blank? || encoded_data.blank?
        return render json: { error: "id and data are required" }, status: :bad_request
      end

      if Blob.exists?(blob_id: blob_id)
        return render json: { error: "Blob already exists" }, status: :conflict
      end

      begin
        raw_data = Base64.strict_decode64(encoded_data)
      rescue ArgumentError
        return render json: { error: "Invalid Base64 data" }, status: :unprocessable_entity
      end

      storage_backend = ENV.fetch("STORAGE_BACKEND", "local")
      storage = Storage::Resolver.call(storage_backend)

      blob = Blob.new(
        blob_id: blob_id,
        storage_type: storage_backend,
        size: raw_data.bytesize
      )

      ActiveRecord::Base.transaction do
        blob.save!
        storage.save(blob: blob, data: raw_data)
      end

      render json: {
        id: blob.blob_id,
        size: blob.size.to_s,
        created_at: blob.created_at.utc.iso8601
      }, status: :created
    rescue StandardError => e
      render json: { error: e.message }, status: :internal_server_error
    end

    def show
      blob = Blob.find_by!(blob_id: params[:id])
      storage = Storage::Resolver.call(blob.storage_type)
      raw_data = storage.fetch(blob: blob)

      render json: {
        id: blob.blob_id,
        data: Base64.strict_encode64(raw_data),
        size: blob.size.to_s,
        created_at: blob.created_at.utc.iso8601
      }, status: :ok
    rescue ActiveRecord::RecordNotFound, Errno::ENOENT
      render json: { error: "Blob not found" }, status: :not_found
    end

    private

    def blob_params
      params.permit(:id, :data)
    end
  end
end