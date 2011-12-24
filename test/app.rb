require 'rubygems'
require 'sinatra'
require 'lib/sinatra/rest-service-auth'

set :keys, %w{34}

get '/' do
	'ok'
end
