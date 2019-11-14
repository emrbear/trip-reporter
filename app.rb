require 'sinatra'
require "sinatra/json"
require "sinatra/reloader" if development?
require_relative 'report_filler'

also_reload './report_filler.rb' if development?
also_reload './signature_pdf.rb' if development?

get '/' do
  json :status => 'ok'
end

post '/api/fill_form' do
  values = JSON.parse(request.body.read)
  report = ReportFiller.fill(values)
  status(report[:error].present? ? 500 : 200)
  json report
rescue StandardError => e
  status(500)
  json error: [e]
end