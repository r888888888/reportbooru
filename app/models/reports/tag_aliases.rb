=begin
from brokeneagle98:

Total: total aliases created/user
Approved: total where 'status' == 'active'
=end

module Reports
	class TagAliases < Base
		def min_changes
			100
		end
		
		def candidates
		end
	end
end
