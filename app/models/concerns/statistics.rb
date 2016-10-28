require 'statistics2'

module Concerns
  module Statistics
    def ci_lower_bound(pos, n, confidence = 0.95)
      if n == 0
        return 0
      end

      z = Statistics2.pnormaldist(1-(1-confidence)/2)
      phat = 1.0*pos/n
      100 * (phat + z*z/(2*n) - z * Math.sqrt((phat*(1-phat)+z*z/(4*n))/n))/(1+z*z/n)
    end

    def deletion_confidence_interval_for(user_id, date, key = :uploader_id)
      deletions = DanbooruRo::Post.where("created_at > ?", date).where(key => user_id, :is_deleted => true).count
      total = DanbooruRo::Post.where("created_at > ?", date).where(key => user_id).count
      ci_lower_bound(deletions, total)
    end

    def negative_score_confidence_interval_for(user_id, date, key = :uploader_id)
      hits = DanbooruRo::Post.where("created_at > ? and score < 0", date).where(key => user_id).count
      total = DanbooruRo::Post.where("created_at > ?", date).where(key => user_id).count
      ci_lower_bound(hits, total)
    end
  end
end
