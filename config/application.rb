require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Reportbooru
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Eastern Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true
    config.x.admin_email = "webmaster@danbooru.donmai.us"
    config.x.danbooru_hostname = "https://danbooru.donmai.us"
    config.x.shared_remote_key = ENV["DANBOORU_SHARED_REMOTE_KEY"]
    config.x.aws_sqs_report_queue_url = ENV["DANBOORU_SQS_REPORT_QUEUE_URL"]
    config.x.aws_sqs_similarity_queue_url = ENV["DANBOORU_SQS_SIMILAR_USER_URL"]
    config.x.aws_sqs_related_tag_queue_url = ENV["DANBOORU_SQS_SIMILAR_TAG_URL"]
  end
end
