module DanbooruRo
  class PostVersion < Base
    attr_readonly *column_names

    def previous
	    if updated_at.to_i == Time.zone.parse("2007-03-14T19:38:12Z").to_i
	      # Old post versions which didn't have updated_at set correctly
	      PostVersion.where("post_id = ? and updated_at = ? and id < ?", post_id, updated_at, id).order("updated_at desc, id desc").first
	    else
	      PostVersion.where("post_id = ? and updated_at < ?", post_id, updated_at).order("updated_at desc, id desc").first
	    end
	  end

	  def diff(version)
	    new_tags = tags.scan(/\S+/)
	    new_tags << "rating:#{rating}" if rating.present?
	    new_tags << "parent:#{parent_id}" if parent_id.present?
	    new_tags << "source:#{source}" if source.present?

	    old_tags = version.present? ? version.tags.scan(/\S+/) : []
	    if version.present?
	      old_tags << "rating:#{version.rating}" if version.rating.present?
	      old_tags << "parent:#{version.parent_id}" if version.parent_id.present?
	      old_tags << "source:#{version.source}" if version.source.present?
	    end

	    added_tags = new_tags - old_tags
	    removed_tags = old_tags - new_tags

	    return {
	      :added_tags => added_tags,
	      :removed_tags => removed_tags
	    }
	  end

	  def diff_previous
	  	diff(previous)
	  end

  end

end
