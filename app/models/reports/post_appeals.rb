=begin
from brokeneagle98:

Total: total post appeals created/user
Successful: total where 'is_resolved' == true
=end

module Reports
	class PostAppeals < Base
		def min_changes
			100
		end
		
		def candidates
			DanbooruRo::NoteVersion.where("updated_at > ?", date_window).group("updater_id").having("count(*) > ?", min_changes)
		end
	end
end
