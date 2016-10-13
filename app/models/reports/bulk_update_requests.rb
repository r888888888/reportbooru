=begin
from brokeneagle98:

Total: total BUR created/user
Approved: total where 'status' == 'approved'
Rejected: total where 'rejected' == 'rejected'
=end

module Reports
	class BulkUpdateRequests < Base
		def min_changes
			100
		end
		
		def candidates
		end
	end
end
