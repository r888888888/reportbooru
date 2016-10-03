module Reports
  class Base
    def storage_service
      @_storage_service ||= begin
        s = Google::Apis::StorageV1::StorageService.new
        s.authorization = Google::Auth.get_application_default([Google::Apis::StorageV1::AUTH_DEVSTORAGE_READ_WRITE])
        s
      end
    end
  end
end
