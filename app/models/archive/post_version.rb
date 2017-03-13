module Archive
  class PostVersion < ActiveRecord::Base
    establish_connection "archive_#{Rails.env}".to_sym

    %w(execute select_value select_values select_all).each do |method_name|
      define_method("#{method_name}_sql") do |sql, *params|
        self.class.connection.__send__(method_name, self.class.sanitize_sql_array([sql, *params]))
      end

      self.class.__send__(:define_method, "#{method_name}_sql") do |sql, *params|
        connection.__send__(method_name, sanitize_sql_array([sql, *params]))
      end
    end
    
    def readonly?
      true
    end

    def destroy
      raise ReadOnlyRecord
    end

    def delete
      raise ReadOnlyRecord
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

    def previous
      self.class.where("post_id = ? and updated_at < ?", post_id, updated_at).order("updated_at desc, id desc").first
    end
  end
end
