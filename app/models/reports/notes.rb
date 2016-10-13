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
