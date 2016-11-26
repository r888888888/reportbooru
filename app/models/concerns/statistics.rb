require 'statistics2'

module Concerns
  module Statistics
    # uses the lower bound of the confidence interval to return a
    # pessimistic mean for a population given a sample of size n,
    # the sample mean, and the sample standard deviation.
    def ci_lower_bound(mean, stddev, n)
      z = 1.96
      mean - (z * stddev / Math.sqrt(n))
    end

    # uses the lower bound of the wilson binomial confidence interval
    # to return a pessimistic probability of success in a population
    # given x successes in n samples.
    def ci_lower_bound_wilson(x, n, confidence = 0.95)
      if n == 0
        return 0
      end

      z = Statistics2.pnormaldist(1-(1-confidence)/2)
      phat = 1.0*x/n
      100 * (phat + z*z/(2*n) - z * Math.sqrt((phat*(1-phat)+z*z/(4*n))/n))/(1+z*z/n)
    end

    def deletion_ci_for(user_id, date, key = :uploader_id)
      deletions = DanbooruRo::Post.where("created_at > ?", date).where(key => user_id, :is_deleted => true).count
      total = DanbooruRo::Post.where("created_at > ?", date).where(key => user_id).count
      ci_lower_bound_wilson(deletions, total)
    end

    def negative_score_ci_for(user_id, date, key = :uploader_id)
      hits = DanbooruRo::Post.where("created_at > ? and score < 0", date).where(key => user_id).count
      total = DanbooruRo::Post.where("created_at > ?", date).where(key => user_id).count
      ci_lower_bound_wilson(hits, total)
    end
  end
end
