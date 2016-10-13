require "big_query"

module BigQuery
  class Base
    def query(q)
      client.query(q)
    rescue Google::Apis::TransmissionError => e
      if e.message =~ /execution expired/
        sleep 5
        retry
      else
        raise
      end
    end

    def escape(s)
      Regexp.escape(s).gsub(/\\/, '\0\0').gsub(/['"]/, '\\\\\0')
    end

    def client
      @_client ||= BigQuery::Client.new(
        "json_key" => client_options[:google_key_path],
        "project_id" => google_config["project_id"],
        "dataset" => client_options[:google_data_set]
      )
    end

    def client_options
      @_client_options ||= {
        pidfile: "/var/run/reportbooru/post_version_exporter.pid",
        logfile: "/var/log/reportbooru/post_version_exporter.log",
        google_key_path: ENV["google_api_key_path"],
        google_data_set: "danbooru_#{Rails.env}"
      }
    end

    def google_config
      @_google_config ||= JSON.parse(File.read(client_options[:google_key_path]))
    end
  end
end
