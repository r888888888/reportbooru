#!/usr/bin/env ruby

require 'pg'
require 'httpclient'
require 'json'

def get_last_synced_post_id(conn)
  results = conn.exec("SELECT value FROM counters WHERE key = 'posts_sync'")
  if results.any?
    results[0]['value']
  else
    0
  end
end

def update_last_synced_post_id(conn, id)
  conn.exec("UPDATE counters SET value = '#{id}' WHERE key = 'posts_sync'")
end

FIELDS = %w(id created_at uploader_id score source md5 last_commented_at rating image_width image_height tag_string is_note_locked fav_count file_ext last_noted_at is_rating_locked parent_id has_children approver_id tag_count_general tag_count_artist tag_count_character tag_count_copyright file_size is_status_locked fav_string pool_string up_score down_score is_pending is_flagged is_deleted tag_count updated_at)

conn = PG.connect(dbname: "danbooru_reporter")
server = "https://danbooru.donmai.us"
danbooru_login = ENV["DANBOORU_LOGIN"]
danbooru_api_key = ENV["DANBOORU_API_KEY"]
last_synced_post_id = get_last_synced_post_id(conn)

http = HTTPClient.new(server)
raw = http.get "#{server}/posts.json", {login: danbooru_login, api_key: danbooru_api_key, limit: 100, tags: "order:id status:any id:>=#{last_synced_post_id}"}
json = JSON.parse(raw.body)

values = FIELDS.map.with_index {|x, i| "$#{i + 1}"}

json.each do |post|
  params = FIELDS.map {|x| post[x]}
  conn.exec("INSERT INTO posts (#{FIELDS.join(', ')}) values (#{values.join(', ')})", params)
  update_last_synced_post_id(conn, post["id"])
end
