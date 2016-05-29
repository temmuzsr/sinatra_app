# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160529120640) do

  create_table "cart_items", force: :cascade do |t|
    t.integer "cart_id",    limit: 4
    t.integer "product_id", limit: 4
    t.integer "quantity",   limit: 4
  end

  add_index "cart_items", ["cart_id"], name: "index_cart_items_on_cart_id", using: :btree
  add_index "cart_items", ["product_id"], name: "index_cart_items_on_product_id", using: :btree

  create_table "carts", force: :cascade do |t|
    t.integer "user_id", limit: 4
  end

  add_index "carts", ["user_id"], name: "index_carts_on_user_id", using: :btree

  create_table "products", force: :cascade do |t|
    t.string "name",  limit: 255
    t.string "price", limit: 255
  end

  create_table "users", force: :cascade do |t|
    t.string "username", limit: 255
    t.string "password", limit: 255
  end

end
