class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.datetime "created_at",                                            :null => false
      t.integer  "uploader_id"
      t.integer  "score",                              :default => 0,     :null => false
      t.text     "source"
      t.text     "md5",                                                   :null => false
      t.datetime "last_commented_at"
      t.string   "rating",              :limit => 1,   :default => "q",   :null => false
      t.integer  "image_width"
      t.integer  "image_height"
      t.text     "tag_string",                         :default => "",    :null => false
      t.boolean  "is_note_locked",                     :default => false, :null => false
      t.integer  "fav_count",                          :default => 0,     :null => false
      t.text     "file_ext",                           :default => "",    :null => false
      t.datetime "last_noted_at"
      t.boolean  "is_rating_locked",                   :default => false, :null => false
      t.integer  "parent_id"
      t.boolean  "has_children",                       :default => false, :null => false
      t.integer  "approver_id"
      t.tsvector "tag_index"
      t.integer  "tag_count_general",                  :default => 0,     :null => false
      t.integer  "tag_count_artist",                   :default => 0,     :null => false
      t.integer  "tag_count_character",                :default => 0,     :null => false
      t.integer  "tag_count_copyright",                :default => 0,     :null => false
      t.integer  "file_size"
      t.boolean  "is_status_locked",                   :default => false, :null => false
      t.text     "fav_string",                         :default => "",    :null => false
      t.text     "pool_string",                        :default => "",    :null => false
      t.integer  "up_score",                           :default => 0,     :null => false
      t.integer  "down_score",                         :default => 0,     :null => false
      t.boolean  "is_pending",                         :default => false, :null => false
      t.boolean  "is_flagged",                         :default => false, :null => false
      t.boolean  "is_deleted",                         :default => false, :null => false
      t.integer  "tag_count",                          :default => 0,     :null => false
      t.datetime "updated_at"
    end

    # add_index "posts", ["approver_id"], :name => "index_posts_on_approver_id"
    # add_index "posts", ["created_at"], :name => "index_posts_on_created_at"
    # add_index "posts", ["file_size"], :name => "index_posts_on_file_size"
    # add_index "posts", ["image_height"], :name => "index_posts_on_image_height"
    # add_index "posts", ["image_width"], :name => "index_posts_on_image_width"
    # add_index "posts", ["last_commented_at"], :name => "index_posts_on_last_commented_at"
    # add_index "posts", ["last_noted_at"], :name => "index_posts_on_last_noted_at"
    # add_index "posts", ["md5"], :name => "index_posts_on_md5", :unique => true
    # add_index "posts", ["parent_id"], :name => "index_posts_on_parent_id"
    # add_index "posts", ["source"], :name => "index_posts_on_source"
    # add_index "posts", ["source"], :name => "index_posts_on_source_pattern"
    # add_index "posts", ["tag_index"], :name => "index_posts_on_tag_index"
    # add_index "posts", ["uploader_id"], :name => "index_posts_on_uploader_id"
    # add_index "posts", ["uploader_ip_addr"], :name => "index_posts_on_uploader_ip_addr"
  end
end
