class Blob < ApplicationRecord
    has_one :blob_content, dependent: :destroy
end
