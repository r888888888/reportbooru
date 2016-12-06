module Reports
  class Base
    def version
      raise NotImplementedError
    end

    def html_template
      raise NotImplementedError
    end

    def candidates
      raise NotImplementedError
    end

    def report_name
      raise NotImplementedError
    end
    
    def sort_key
      raise NotImplementedError
    end

    def file_name
      "#{date_string}_v#{version}"
    end

    def date_window
      30.days.ago
    end

    def date_string
      Time.now.strftime("%F")
    end

    def base_directory
      ENV["BASE_REPORTS_DIR"]
    end

    def report_directory
      File.join(base_directory, report_name)
    end

    def report_path(ext)
      File.join(report_directory, file_name + "." + ext)
    end

    def generate
      htmlf = File.open(report_path("html"), "w")
      jsonf = File.open(report_path("json"), "w")

      begin
        data = []

        candidates.each do |user_id|
          data << calculate_data(user_id)
          puts data.inspect if $DEBUG
        end

        data = data.sort_by {|x| -x[sort_key].to_i}

        engine = Haml::Engine.new(html_template)
        htmlf.write(engine.render(Object.new, data: data, date_window: date_window))

        jsonf.write("[")
        jsonf.write(data.map {|x| x.to_json}.join(","))
        jsonf.write("]")
      ensure
        jsonf.close
        htmlf.close
      end
    end
  end
end
