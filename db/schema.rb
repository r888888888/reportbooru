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

ActiveRecord::Schema.define(version: 20150501204116) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "counters", force: :cascade do |t|
    t.string "key"
    t.text   "value"
  end

  add_index "counters", ["key"], name: "index_counters_on_key", unique: true, using: :btree

  create_table "posts", force: :cascade do |t|
    t.datetime "created_at",                                    null: false
    t.integer  "uploader_id"
    t.integer  "score",                         default: 0,     null: false
    t.text     "source"
    t.text     "md5",                                           null: false
    t.datetime "last_commented_at"
    t.string   "rating",              limit: 1, default: "q",   null: false
    t.integer  "image_width"
    t.integer  "image_height"
    t.text     "tag_string",                    default: "",    null: false
    t.boolean  "is_note_locked",                default: false, null: false
    t.integer  "fav_count",                     default: 0,     null: false
    t.text     "file_ext",                      default: "",    null: false
    t.datetime "last_noted_at"
    t.boolean  "is_rating_locked",              default: false, null: false
    t.integer  "parent_id"
    t.boolean  "has_children",                  default: false, null: false
    t.integer  "approver_id"
    t.tsvector "tag_index"
    t.integer  "tag_count_general",             default: 0,     null: false
    t.integer  "tag_count_artist",              default: 0,     null: false
    t.integer  "tag_count_character",           default: 0,     null: false
    t.integer  "tag_count_copyright",           default: 0,     null: false
    t.integer  "file_size"
    t.boolean  "is_status_locked",              default: false, null: false
    t.text     "fav_string",                    default: "",    null: false
    t.text     "pool_string",                   default: "",    null: false
    t.integer  "up_score",                      default: 0,     null: false
    t.integer  "down_score",                    default: 0,     null: false
    t.boolean  "is_pending",                    default: false, null: false
    t.boolean  "is_flagged",                    default: false, null: false
    t.boolean  "is_deleted",                    default: false, null: false
    t.integer  "tag_count",                     default: 0,     null: false
    t.datetime "updated_at"
  end

end
