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

    def self.export_missing
      client = BigQuery::PostVersion.new(4.months.ago)
      calculate_diff = lambda do |older, newer|
        if older
          older_tags = older.tags.scan(/\S+/)
          older_tags << "rating:#{older.rating}" if older.rating.present?
          older_tags << "parent:#{older.parent_id}" if older.parent_id.present?
          older_tags << "source:#{older.source}" if older.source.present?
        else
          older_tags = []
        end

        newer_tags = newer.tags.scan(/\S+/)
        newer_tags << "rating:#{newer.rating}" if newer.rating.present?
        newer_tags << "parent:#{newer.parent_id}" if newer.parent_id.present?
        newer_tags << "source:#{newer.source}" if newer.source.present?

        added_tags = newer_tags - older_tags
        removed_tags = older_tags - newer_tags

        {
          :added_tags => added_tags,
          :removed_tags => removed_tags
        }
      end

      where("created_at >= ?", 4.months.ago).find_each do |version|
        batch = []
        if !client.post_version_exists?(version.version, version.post_id)
          previous = version.previous
          diff = calculate_diff.call(previous, version)
          vnum = version.version
          
          diff[:added_tags].each do |added_tag|
            hash = {
              "version_id" => version.id,
              "version" => vnum,
              "updated_at" => version.updated_at,
              "post_id" => version.post_id,
              "added_tag" => added_tag,
              "updater_id" => version.updater_id,
              "updater_ip_addr" => version.updater_ip_addr.to_s
            }
            batch << hash
          end

          diff[:removed_tags].each do |removed_tag|
            hash = {
              "version_id" => version.id,
              "version" => vnum,
              "updated_at" => version.updated_at,
              "post_id" => version.post_id,
              "removed_tag" => removed_tag,
              "updater_id" => version.updater_id,
              "updater_ip_addr" => version.updater_ip_addr.to_s
            }
            batch << hash
          end

          if diff[:added_tags].empty? && diff[:removed_tags].empty?
            hash = {
              "version_id" => version.id,
              "version" => vnum,
              "updated_at" => version.updated_at,
              "post_id" => version.post_id,
              "updater_id" => version.updater_id,
              "updater_ip_addr" => version.updater_ip_addr.to_s
            }
            batch << hash
          end

          partition_timestamp = batch[0]["updated_at"].strftime("%Y%m%d")
          puts "inserting #{version.id} (#{version.post_id}.#{version.version})"
          result = client.client.insert("post_versions_flat_part$#{partition_timestamp}", batch)
        end
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
