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
		end
	end
end
