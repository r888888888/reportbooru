module Reports
  class Uploads < Base
    include Concerns::Statistics

    def sort_key
      :total
    end
    
    def calculate_data(user_id)
      user = DanbooruRo::User.find(user_id)
      name = user.name
      privs = []
      client = BigQuery::PostVersion.new(date_window)
      total = DanbooruRo::Post.where("created_at > ?", date_window).where(uploader_id: user.id).count
      queue_bypass = DanbooruRo::Post.where("created_at > ?", date_window).where(uploader_id: user.id, approver_id: nil, is_deleted: false, is_pending: false).count
      deleted = DanbooruRo::Post.where("created_at > ?", date_window).where(uploader_id: user.id, is_deleted: true).count
      parent = DanbooruRo::Post.where("created_at > ? and parent_id is not null", date_window).where(uploader_id: user.id).count
      source = DanbooruRo::Post.where("created_at > ? and source <> '' and source is not null", date_window).where(uploader_id: user.id).count
      safe = DanbooruRo::Post.where("created_at > ?", date_window).where(uploader_id: user.id, rating: "s").count
      questionable = DanbooruRo::Post.where("created_at > ?", date_window).where(uploader_id: user.id, rating: "q").count
      explicit = DanbooruRo::Post.where("created_at > ?", date_window).where(uploader_id: user.id, rating: "e").count
      post_count = safe + questionable + explicit
      safe = "%d%%" % (100 * safe.to_f / post_count.to_f)
      questionable = "%d%%" % (100 * questionable.to_f / post_count.to_f)
      explicit = "%d%%" % (100 * explicit.to_f / post_count.to_f)
      general = client.count_general_added_v1(user_id)
      character = client.count_character_added_v1(user_id)
      copyright = client.count_copyright_added_v1(user_id)
      artist = client.count_artist_added_v1(user_id)
      comic = DanbooruRo::Post.where("created_at > ?").where(uploader_id: user.id).raw_tag_match("comic").count
      med_score = DanbooruRo::Post.select_value_sql("select percentile_cont(0.50) within group (order by score) from posts where created_at >= ? and uploader_id = ?", date_window, user.id).to_i
      del_conf = "%.1f%" % deletion_ci_for(user_id, date_window)
      neg_conf = "%.1f%" % negative_score_ci_for(user_id, date_window)
      comic_ratio = "%.1f%" % (100 * comic.to_f / post_count.to_f)
      uniq_flaggers = DanbooruRo::PostFlag.joins("join posts on post_flags.post_id = posts.id").where("posts.created_at > ? and posts.is_deleted = true and posts.uploader_id = ?", date_window, user_id).distinct.count("post_flags.creator_id")
      uniq_downvoters = DanbooruRo::PostVote.joins("join posts on post_votes.post_id = posts.id").where("posts.created_at > ? and post_votes.score < 0 and posts.uploader_id = ?", date_window, user_id).distinct.count("post_votes.user_id")

      return {
        id: user_id,
        name: name,
        level_string: user.level_string,
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
        artist: artist,
        comic: comic,
        comic_ratio: comic_ratio,
        med_score: med_score,
        del_conf: del_conf,
        neg_conf: neg_conf,
        uniq_flaggers: uniq_flaggers,
        uniq_downvoters: uniq_downvoters
      }
    end
  end
end
