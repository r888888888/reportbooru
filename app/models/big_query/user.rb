module BigQuery
  class User < Base
    SCHEMA = {
      id: {type: "INTEGER"},
      created_at: {type: "TIMESTAMP"},
      updated_at: {type: "TIMESTAMP"},
      name: {type: "STRING"},
      inviter_id: {type: "INTEGER"},
      level: {type: "INTEGER"},
      last_logged_in_at: {type: "TIMESTAMP"},
      post_upload_count: {type: "INTEGER"},
      post_update_count: {type: "INTEGER"},
      note_update_count: {type: "INTEGER"},
      favorite_count: {type: "INTEGER"},
      last_ip_addr: {type: "STRING"}
    }

    def export!
      begin
        client.delete_table("users")
      rescue Google::Apis::ClientError
      end
      
      client.create_table("users", SCHEMA)

      DanbooruRo::User.find_in_batches do |group|
        batch = group.map do |x| 
          {
            "id" => x.id,
            "created_at" => x.created_at,
            "updated_at" => x.updated_at,
            "name" => x.name,
            "inviter_id" => x.inviter_id,
            "level" => x.level,
            "last_logged_in_at" => x.last_logged_in_at,
            "post_upload_count" => x.post_upload_count,
            "post_update_count" => x.post_update_count,
            "note_update_count" => x.note_update_count,
            "favorite_count" => x.favorite_count,
            "last_ip_addr" => x.last_ip_addr
          }
        end

        client.insert("users", batch)
      end
    end
  end
end
