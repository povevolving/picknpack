class CreateBatches < ActiveRecord::Migration[5.0]
  def change
    create_table :batches do |t|
      t.attachment :csv_original
      t.attachment :csv_processed
      t.boolean :label_printed
      t.timestamps
    end
  end
end
