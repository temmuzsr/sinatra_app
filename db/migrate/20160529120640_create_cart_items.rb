class CreateCartItems < ActiveRecord::Migration
  def change
  	create_table :cart_items do |t|
      t.references :cart, index: true
      t.references :product, index: true
      t.integer :quantity
    end  
  end
end
