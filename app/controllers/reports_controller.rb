class ReportsController < ApplicationController
  def uploads
    @report = UploadReport.new(params[:min], params[:max], params[:tags].split(/,/), params[:scale])
    render layout: false
  end
end
