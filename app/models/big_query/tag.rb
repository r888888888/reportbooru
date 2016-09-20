module BigQuery
  class Tag < Base
    SCHEMA = {
      id: {type: "INTEGER"},
      name: {type: "STRING"},
      count: {type: "INTEGER"},
      category: {type: "INTEGER"},
      created_at: {type: "TIMESTAMP"},
      updated_at: {type: "TIMESTAMP"}
    }

    def export!
      begin
        client.delete_table("tags")
      rescue Google::Apis::ClientError
      end
      
      client.create_table("tags", SCHEMA)

      ::Tag.find_in_batches do |group|
        batch = group.map do |x| 
          {
            "id" => x.id,
            "name" => x.name,
            "count" => x.post_count,
            "category" => x.category,
            "created_at" => x.created_at,
            "updated_at" => x.updated_at
          }
        end

        client.insert("tags", batch)
      end
    end
  end
end
