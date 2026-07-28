class CreateBlobs < ActiveRecord::Migration[8.1]
  def change
    create_table :blobs do |t|
      t.string :blob_id, null: false
      t.string :storage_type, null: false
      t.integer :size, null: false

      t.timestamps
    end

    add_index :blobs, :blob_id, unique: true
  end
end