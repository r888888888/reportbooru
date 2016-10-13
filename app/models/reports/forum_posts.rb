=begin
from brokeneagle98:

Total: total forum posts created/user
Updates: total of forum posts where 'created_at' != 'updated_at'
=end

module Reports
	class ForumPosts < Base
		def min_changes
			100
		end
		
		def candidates
			DanbooruRo::NoteVersion.where("updated_at > ?", date_window).group("updater_id").having("count(*) > ?", min_changes)
		end
	end
end
