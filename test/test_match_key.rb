require 'test/helper'
require 'test/unit'
require 'rack/test'
require 'sinatra'
require 'sinatra/rest-service-auth'
require 'digest'

ENV['RACK_ENV'] = 'test'

class App1 < Sinatra::Base
  register Sinatra::RESTServiceAuth

  set :keys, %w{34 54}

  get '/' do
    'ok'
  end
end

class TestKeyFromEnumerable < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    App1.new
  end

  def test_auth
    q   = '?key=34'
    url = "http://example.org/#{q}"
    sig = Digest::SHA2.new(256).hexdigest(url)
    get "/#{q}&sig=#{sig}"
    assert last_response.ok?, "request should succeed"
  end
end

class TestModel
  attr_reader :key

  def initialize(key)
    @key = key
  end

  def self.all
    %w{34 54}.map { |k| self.new(k) }
  end
end

class App2 < Sinatra::Base
  register Sinatra::RESTServiceAuth

  set :keys, TestModel

  get '/' do
    'ok'
  end
end

class TestKeyFromModel < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    App2.new
  end

  def test_all_method
    assert TestModel.respond_to?(:all)
  end

  def test_select
    assert !TestModel.all.select { |x| x.key == '34' }.empty?
  end

  def test_auth
    q   = '?key=34'
    url = "http://example.org/#{q}"
    sig = Digest::SHA2.new(256).hexdigest(url)
    get "/#{q}&sig=#{sig}"
    assert last_response.ok?, "request should succeed"
  end
end

class App3 < Sinatra::Base
  register Sinatra::RESTServiceAuth

  set :keys, lambda { %w{34 54} }

  get '/' do
    'ok'
  end
end

class TestKeyFromLambda < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    App3.new
  end

  def test_auth
    q   = '?key=34'
    url = "http://example.org/#{q}"
    sig = Digest::SHA2.new(256).hexdigest(url)
    get "/#{q}&sig=#{sig}"
    assert last_response.ok?, "request should succeed"
  end
end

class App4 < Sinatra::Base
  register Sinatra::RESTServiceAuth

  authorize_when { |k, s| k == '34' }

  get '/' do
    'ok'
  end
end

class TestMatchKey < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    App4.new
  end

  def test_auth
    q   = '?key=34'
    url = "http://example.org/#{q}"
    sig = Digest::SHA2.new(256).hexdigest(url)
    get "/#{q}&sig=#{sig}"
    File.open('errors.html', 'w') do |f|
      f.write last_response.body
    end
    assert last_response.ok?, "request should succeed"
  end
end

class App5 < Sinatra::Base
  register Sinatra::RESTServiceAuth

  set :keys, 'config-single.yml'

  get '/' do
    'ok'
  end
end

class TestKeyFromFileWithSingleKey < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    App5.new
  end

  def test_file_exists
    assert File.exists?(File.expand_path(File.join(settings.root, 'config-single.yml')))
  end

  def test_auth
    q   = '?key=34'
    url = "http://example.org/#{q}"
    sig = Digest::SHA2.new(256).hexdigest(url)
    get "/#{q}&sig=#{sig}"
    assert last_response.ok?, "request should succeed"
  end
end
