class ReportsController < ApplicationController
  def uploads
    @report = UploadReport.new(params[:min], params[:max], params[:tags])
    render layout: false
  end
end
