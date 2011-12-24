require 'digest'
require 'yaml'
require 'sinatra/base'
require 'uri'

module Sinatra
  module RESTServiceAuth
		module DSL
			def match_key(&block)
				if block
					@@match_key = block
				else
					@@match_key
				end
			end
		end

		# set defaults
		def self.registered(app)
			app.send(:set, :key, nil)
			app.send(:set, :match_key, nil)
		end

    # `authorized? -> Boolean`
    #
    # Return true if `params[:key]` matches key store (see `match_key`) and
    # `params[:sig]` matches a SHA256 hash of the base URL.
    def authorized?
      key, sig = params[:key], params[:sig]
      match_key(key) && sig == gen_sig(base_url)
    end
  
    # `block!`
    #
    # Throws HTTP 401 error
    def block!
      response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
      throw(:halt, [401, "Not authorized\n"])
    end
  
    # `match_key(key) -> Boolean`
    #
    # Used with:
    #    set :keys, Keys 
    #
    # where can be:
    #    1) a Model that responds to :all and returns an Enumerable,
    #    2) an Enumerable
    #    3) a lambda or Proc that returns an Enumerable
    #    4) a path with to a YAML file with a key named 'key' or 'keys'
    #       where key specifies a single key or keys specifies a list of keys
    #
    #  By default it will look for a YAML file at app_root/config.yml
    #
    # `set :match_key, lambda {}` can be used instead of `set :keys` in this
    # case the lambda or Proc must return a boolean value.
    # 
    # Using this method you can implement your own key checking.
    def match_key(key)
      if @key then @key == key
      else
        if settings.respond_to?(:keys) && settings.keys
					keys = settings.keys

          if keys.respond_to?(:all)
            r = find_key(key, keys.all) { |x| x.key == key }
            @key = r && r.key

          elsif (not keys.is_a?(String)) && keys.respond_to?(:each)
            @key = find_key key, keys
          
          else
						file = File.exists?(keys) ? keys : File.join(settings.root, keys)

            @key = load_key_from_file file, key
          end
          
          @key == key
        elsif (block = self.class.send(:match_key)) && block.respond_to?(:call)
          !!block.call(key, gen_sig(base_url))
        else
          @key = load_key_from_file File.expand_path(File.join(settings.root, 'config.yml')), key

					@key == key
        end
      end
    end
  
    private

		def load_key_from_file(file, key)
      if File.exists?(file)
				config = YAML.load_file(file)
				
				if keys = config['keys']
					find_key key, keys
				else
					config['key']
				end
			end.to_s # ensure a string is returned
		end

		def find_key(key, enum, &block)
			if block
				enum.select(&block).first
			else
				enum.select { |x| x == key }.first
			end
		end

    def gen_sig(str)
      Digest::SHA2.new(256).hexdigest(str)
    end

    def base_url
      url    = request.url
      query  = query_string url
      params = query_params query
      url    = url.sub(query, '')
      query  = params.reject { |x| x.first == 'sig' }.map { |x| "#{x.first}=#{x.last}" }.join('&')

      "#{url}#{query}"
    end

    def query_params(query)
      query.split('&').map { |p| p.split('=') }.sort { |a, b| a.first <=> b.first }
    end

    def query_string(url)
      ((parts = URI.split url) && parts[7]).to_s # ensure a string is returned
    end
  end

  helpers RESTServiceAuth
	register RESTServiceAuth::DSL
end
