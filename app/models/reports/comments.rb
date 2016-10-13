=begin
from brokeneagle98:

Total: total comments created/user
Updates: total of comments where 'created_at' != 'updated_at'
Bumps: total where 'do_not_bump_post' == false
Pos Count: total where 'score' > 0
Neg Count: total where 'score' < 0
Score: cumulative score for all comments
=end

module Reports
	class Comments < Base
		def min_changes
			100
		end
		
		def candidates
		end
	end
end
