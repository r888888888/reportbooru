=begin
from brokeneagle98:

The following is disregarded if there is a corresponding artist version (See Artist above for implementation details)
Total: total versions/user
Creates: no prior version
Title: title changed
Other Name: other names changed
Body Edits: body changed
Other: no changes, i.e. none of the conditions above are true
=end

module Reports
	class WikiPages < Base
		def min_changes
			100
		end
		
		def candidates
		end
	end
end
