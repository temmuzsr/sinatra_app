class Cart < ActiveRecord::Base
	has_many :cart_items, dependent: :destroy
	belongs_to :user

	def total_price
		@total = 0
		cart_items.each do |cart_item|
			@total = @total+(cart_item.quantity * cart_item.product.price.to_i)
		end
		@total
	end
end