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

ActiveRecord::Schema.define(version: 20150720222615) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "post_view_hits", force: :cascade do |t|
    t.date    "date",                null: false
    t.integer "post_id",             null: false
    t.integer "count",   default: 0, null: false
  end

  add_index "post_view_hits", ["date", "post_id"], name: "index_post_view_hits_on_date_and_post_id", unique: true, using: :btree

end
