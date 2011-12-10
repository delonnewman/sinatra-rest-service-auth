require 'digest'
require 'yaml'
require 'sinatra/base'

module Sinatra
	module RESTServiceAuth
  	def base_url
  		request.url.gsub(/\&sig\=.*/, '')
  	end
  
  	def authorized?
  		key, sig = params[:key], params[:sig]
  		key == get_key && sig == sha256(base_url)
  	end
  
  	def block!
  		response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
  		throw(:halt, [401, "Not authorized\n"])
  	end
  
  	def get_key
  		@key ||= ((config = YAML.load_file(File.expand_path(File.join(settings.root, 'config.yml')))) && config['key'])
  	end
  
  	def sha256(str)
  		Digest::SHA2.new(256).hexdigest(str)
  	end
	end

	helpers RESTServiceAuth
end
