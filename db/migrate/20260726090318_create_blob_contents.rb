class CreateBlobContents < ActiveRecord::Migration[8.1]
  def change
    create_table :blob_contents do |t|
      t.references :blob, null: false, foreign_key: true
      t.binary :data, null: false

      t.timestamps
    end
  end
end