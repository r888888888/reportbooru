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

    def self.export
      client.delete_table("tags")
      client.create_table("tags", SCHEMA)

      ::Tag.find_in_batches do |group|
        batch = group.map do |x| 
          {
            "id" => tag.id,
            "name" => tag.name,
            "count" => tag.post_count,
            "category" => tag.category,
            "created_at" => tag.created_at,
            "updated_at" => tag.updated_at
          }
        end

        client.insert("tags", batch)
      end
    end
  end
end
