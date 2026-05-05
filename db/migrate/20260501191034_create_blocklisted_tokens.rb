class CreateBlocklistedTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :blocklisted_tokens do |t|
      t.string :token
      t.datetime :exp

      t.timestamps
    end
    add_index :blocklisted_tokens, :token
  end
end
