require 'sinatra'
require "sinatra/json"
require "sinatra/reloader" if development?

get '/' do
  json :status => 'ok'
end