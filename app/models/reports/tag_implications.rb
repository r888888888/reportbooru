=begin
from brokeneagle98:

Total: total implications created/user
Approved: total where 'status' == 'active'
=end

module Reports
	class TagImplications < Base
		def min_changes
			100
		end
		
		def candidates
		end
	end
end
