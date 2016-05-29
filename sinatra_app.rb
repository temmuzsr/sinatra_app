require 'rubygems'
require 'sinatra'
require 'sinatra/base'
require 'warden'
require 'pry'
require "sinatra/activerecord"
require "./db_connection"
require "./models/user"
require "./models/product"
require "./models/cart_item"
require "./models/cart"

class SinatraApp < Sinatra::Base

  enable :sessions
  enable :method_override
  # use Rack::Session::Cookie


	use Warden::Manager do |config|
		config.default_strategies :password
		config.serialize_into_session{|user| user.id}
		config.serialize_from_session{|id| User.find(id) }
		config.failure_app = self
	end


	Warden::Manager.before_failure do |env,opts|
	    # Because authentication failure can happen on any request but
	    # we handle it only under "post '/auth/unauthenticated'", we need
	    # to change request to POST
	    env['REQUEST_METHOD'] = 'POST'
	    # And we need to do the following to work with  Rack::MethodOverride
	    env.each do |key, value|
	    	env[key]['_method'] = 'post' if key == 'rack.request.form_hash'
	    end
	end

  use Warden::Manager do |config|
    config.default_strategies :password
    config.serialize_into_session{|user| user.id}
    config.serialize_from_session{|id| User.find(id) }
    config.failure_app = self
  end


  Warden::Manager.before_failure do |env,opts|
    # Because authentication failure can happen on any request but
    # we handle it only under "post '/auth/unauthenticated'", we need
    # to change request to POST
    env['REQUEST_METHOD'] = 'POST'
    # And we need to do the following to work with  Rack::MethodOverride
    env.each do |key, value|
      env[key]['_method'] = 'post' if key == 'rack.request.form_hash'
    end
  end

  Warden::Strategies.add(:password) do
    def valid?
      params['username'] && params['password']
    end

		def authenticate!
	    	# u = User.authenticate(params['username'], params['password'])
	    	u = User.find_by(username: params['username'])
	    	if u.present?
	    		u.authenticate(params[:password])
	    	end
	    	u.nil? ? fail!("Could not log in") : success!(u)
	    end
	end
  # ----


  def current_cart
    if session[:cart_id]
      @current_cart ||= Cart.find(session[:cart_id])
    end
    if session[:cart_id].nil?
      @current_cart = Cart.create!
      session[:cart_id] = @current_cart.id
    end
    @current_cart
  end


  get "/" do
    erb :index
  end

  # --auth

	post "/unauthenticated" do
		@error = "unauthenticated.Try again"
		erb :index
	end

	post "/auth/login" do
		env['warden'].authenticate!
		if env['warden'].authenticated?
			@user = env['warden'].user
			redirect "/users/#{@user.id}" 
		else
			@error = "Try again"
			erb :index
		end
	end

  get "/auth/logout" do
    env['warden'].raw_session.inspect
    env['warden'].logout
    @success = "logged out"
    redirect '/'
  end

  # --user
  get "/users" do
    @users = User.all
    erb :index_users
  end

  post "/users" do
    user = User.new
    user.username = params[:username]
    user.password = params[:password]
    user.save
    redirect "/users/#{user.id}"
  end

  get "/users/:id" do
    @user = User.find(params[:id])
    erb :show_user
  end

	get "/users/:id/carts" do
		if session[:cart_id]
			@current_cart ||= Cart.find(session[:cart_id])
		end
		@user.carts << @current_cart
		@user.save
		redirect "/users/:id"
	end


  post "/users/:id/carts" do
    @user = User.find(params[:id])
    @cart = Cart.new
    @user.cart << @cart
    @user.save
    erb :show_user
  end


  # --products
  get "/products" do
    if session[:cart_id]
      @current_cart ||= Cart.find(session[:cart_id])
    end
    if session[:cart_id].nil?
      @current_cart = Cart.create!
      session[:cart_id] = @current_cart.id
    end
    @products = Product.all
    erb :index_products
  end

  post "/products" do
    @product = Product.new
    @product.name = params[:name]
    @product.price = params[:price]
    @product.save
    if session[:cart_id]
      @current_cart ||= Cart.find(session[:cart_id])
    end
    if session[:cart_id].nil?
      @current_cart = Cart.create!
      session[:cart_id] = @current_cart.id
    end
    @success = "Product added."
    redirect "/products"
  end

  get "/product/:id" do
    @product = Product.find(params[:id])
    erb :show_product
  end

  # --cart

  get "/carts/:cart_id" do
    @cart = Cart.find(params[:cart_id])
    @price = @cart.total_price
    erb :show_cart
  end

  post "/carts/:cart_id/products" do
    @cart = Cart.find(params[:cart_id])
    @cart.user = env['warden'].user
    @temp_item = CartItem.find_by(product_id: params[:product_id])
    puts params[:cart_id]
    puts params[:product_id]
    if @cart.cart_items.include?(@temp_item)
      @cart.cart_items.each do |item|
	if item.id == @temp_item.id
	  item.quantity +=  params[:quantity]
	  item.save
	end
      end
    else
      @cart_item = CartItem.new
      @cart_item.product_id = params[:product_id]
      @cart_item.cart_id = @cart.id
      if params[:quantity].present?
	@cart_item.quantity = params[:quantity]
      else
	@cart_item.quantity = 1
      end
      @cart_item.save
      @cart.cart_items << @cart_item
      @cart.save
    end
    redirect "/carts/#{@cart.id}"
  end

  delete "/carts/:cart_id/products/:product_id" do
    @cart = Cart.find(params[:cart_id])
    @cart_item_to_be_deleted = @cart.cart_items.where(product_id: params[:product_id]).first
    @cart_item_to_be_deleted.destroy
    redirect "/carts/#{@cart.id}"
  end

  put "/carts/:cart_id/products/:product_id" do
    @cart = Cart.find(params[:cart_id])

    @cart_item_to_be_updated = @cart.cart_items.where(product_id: params[:product_id]).first
    @cart_item_to_be_updated.quantity = @cart_item_to_be_updated.quantity + params[:quantity].to_i
    @cart_item_to_be_updated.save
    redirect "/carts/#{@cart.id}"

  end

  put "/carts/:cart_id/clean" do
    @cart = Cart.find(params[:cart_id])
    @cart.cart_items.delete_all
    redirect "/carts/#{@cart.id}"
  end

end

# Rack::Builder.new do
#   use Rack::Session::Cookie, :secret => "replace this with some secret key"

#   use Warden::Manager do |manager|
#     manager.default_strategies :password, :basic
#     manager.failure_app = BadAuthenticationEndsUpHere
#   end

#   run SinatraApp
# end

run SinatraApp.run!
