class CreateIntegrityLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :integrity_logs do |t|
      t.string :idfa
      t.integer :ban_status
      t.string :ip
      t.boolean :rooted_device
      t.string :country
      t.boolean :vpn
      t.boolean :proxy

      t.timestamps
    end
  end
end
