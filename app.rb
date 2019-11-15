require 'sinatra'
require "sinatra/json"
require "sinatra/reloader" if development?
require_relative 'lib/trip_reporter'

also_reload './report_filler.rb' if development?
also_reload './signature_pdf.rb' if development?

get '/' do
  json :status => 'ok'
end

post '/api/ahcccs/v2019/fill' do
  begin
    values = JSON.parse(request.body.read)
    report = TripReporter::Ahcccs::V2019::Report.fill(values)
    status(report[:error].present? ? 500 : 200)
    json report
  rescue StandardError => e
    status(500)
    json error: [e]
  end
end