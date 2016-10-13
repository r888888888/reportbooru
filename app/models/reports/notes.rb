=begin
from brokeneagle98:

Total: total versions/user
Creates: no prior version
Edits: body changed
Moves: x,y changes
Resizes: width,height changes
Deletes: isactive "True" -> "False"
Undeletes: isactive "True" -> "False"
Other: no changes, i.e. none of the conditions above are true
=end

module Reports
	class Notes < Base
		def min_changes
			100
		end
		
		def candidates
			DanbooruRo::NoteVersion.where("updated_at > ?", date_window).group("updater_id").having("count(*) > ?", min_changes)
		end
	end
end
