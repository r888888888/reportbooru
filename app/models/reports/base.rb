module Reports
  class Base
    def version
      raise NotImplementedError
    end

    def html_template
      raise NotImplementedError
    end

    def file_name
      raise NotImplementedError
    end

    def candidates
      raise NotImplementedError
    end

    def report_name
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

    def storage_service
      @_storage_service ||= begin
        s = Google::Apis::StorageV1::StorageService.new
        s.authorization = Google::Auth.get_application_default([Google::Apis::StorageV1::AUTH_DEVSTORAGE_READ_WRITE])
        s
      end
    end

    def upload(file, name, content_type)
      data = {
        content_type: content_type
      }

      storage_service.insert_object("danbooru-reports", data, name: "#{report_name}/#{name}", content_type: content_type, upload_source: file.path)
    end

  end
end
