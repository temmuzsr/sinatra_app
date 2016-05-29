
class User < ActiveRecord::Base
	has_many :carts
	def authenticate(pass)
		if self.password == pass
		  true
		else
		  false
		end
	end

end