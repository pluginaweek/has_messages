class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
      t.references :sender, :polymorphic => true, :null => false
      t.text :subject, :body
      t.string :state, :null => false
      t.datetime :hidden_at
      t.string :type
      t.timestamps
    end
  end

  def self.down
    drop_table :messages
  end
end
