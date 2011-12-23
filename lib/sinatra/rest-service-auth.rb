require 'digest'
require 'yaml'
require 'sinatra/base'
require 'uri'

module Sinatra
  module RESTServiceAuth
    def authorized?
      key, sig = params[:key], params[:sig]
      match_key(key) && sig == sha256(base_url)
    end
  
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
    #      where key specifies a single key or keys specifies a list of keys
    #
    #  By default it will look for a YAML file at app_root/config.yml
    #
    #  `set :match_key, lambda {}` can be used instead of `set :keys`
    # in this case the lambda or Proc must return a boolean value.
    # Using this method you can implement your own key checking.
    def match_key(key)
      if @key then @key == key
      else
        if settings.keys
          if settings.keys.respond_to?(:all)
            @key = settings.keys.all.select { |x| x.key == key }.first

          elsif settings.keys.respond_to?(:each)
            @key = settings.keys.select { |x| x.key == key }.first
          
          elsif settings.keys.respond_to?(:call)
            @key = settings.keys.call.select { |x| x.key == key }.first
          
          else
            file = settings.keys || File.expand_path(File.join(settings.root, 'config.yml'))
    
            if File.exists?(file)
              config = YAML.load_file(file)

              @key =
                if keys = config['keys']
                  keys.select { |x| x == key }.first
                else
                  config['key']
                end
            end
          end
          
          @key == key
        elsif settings.match_key && settings.match_key.respond_to?(:call)
          !!settings.match_key.call(key)
        else
          false
        end
      end
    end
  
    private

    def sha256(str)
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
end
