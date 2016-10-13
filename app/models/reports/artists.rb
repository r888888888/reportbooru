=begin
from brokeneagle98:

Total: total versions/user
Creates: no prior version
Name: name changed
Other Name: other names changed
Url: url string changed
Group: group name changed
Deletes: isactive "True" -> "False"
Undeletes: isactive "True" -> "False"
Other: no changes, i.e. none of the conditions above are true
The following is determined by searching for a corresponding wiki page version
Wiki:
	Search for wiki page with same 'title' as artist 'name'; if none exists then break
	Search through wiki page versions for
		wiki page version 'updated_at' timestamp within 1 second of artist version 'updated_at' timestamp
			and
		wiki page version 'updater_id' equal to artist version 'updater_id'
=end

module Reports
	class Artists < Base
		def min_changes
			100
		end
		
		def candidates
		end
	end
end
