require 'sinatra'
require "sinatra/json"
require "sinatra/reloader" if development?
require_relative 'report_filler'

also_reload './report_filler.rb'
also_reload './signature_pdf.rb'

get '/' do
  json :status => 'ok'
end

post '/api/fill_form' do 
  values = JSON.parse(request.body.read)
  json ReportFiller.fill(values)
end