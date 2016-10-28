module Reports
  class Uploads < Base
    def sort_key
      :total
    end
    
    def calculate_data(user_id)
      user = DanbooruRo::User.find(user_id)
      name = user.name
      client = BigQuery::PostVersion.new
      tda = date_window.strftime("%F %H:%M")
      total = DanbooruRo::Post.where("created_at > ?", date_window).where(uploader_id: user.id).count
      queue_bypass = DanbooruRo::Post.where("created_at > ?", date_window).where(uploader_id: user.id, approver_id: nil, is_deleted: false, is_pending: false).count
      deleted = DanbooruRo::Post.where("created_at > ?", date_window).where(uploader_id: user.id, is_deleted: true).count
      parent = DanbooruRo::Post.where("created_at > ? and parent_id is not null", date_window).where(uploader_id: user.id).count
      source = DanbooruRo::Post.where("created_at > ? and source <> '' and source is not null", date_window).where(uploader_id: user.id).count
      safe = DanbooruRo::Post.where("created_at > ?", date_window).where(uploader_id: user.id, rating: "s").count
      questionable = DanbooruRo::Post.where("created_at > ?", date_window).where(uploader_id: user.id, rating: "q").count
      explicit = DanbooruRo::Post.where("created_at > ?", date_window).where(uploader_id: user.id, rating: "e").count
      general = client.count_general_added_v1(user_id, tda)
      character = client.count_character_added_v1(user_id, tda)
      copyright = client.count_copyright_added_v1(user_id, tda)
      artist = client.count_artist_added_v1(user_id, tda)

      return {
        id: user_id,
        name: name,
        level: user.level,
        total: total,
        queue_bypass: queue_bypass,
        deleted: deleted,
        parent: parent,
        source: source,
        safe: safe,
        questionable: questionable,
        explicit: explicit,
        general: general,
        character: character,
        copyright: copyright,
        artist: artist
      }
    end
  end
end
