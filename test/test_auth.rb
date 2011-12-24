require 'test/helper'
require 'test/unit'
require 'rack/test'
require 'sinatra'
require 'sinatra/rest-service-auth'
require 'digest'

ENV['RACK_ENV'] = 'test'

class TestApp < Sinatra::Base
  register Sinatra::RESTServiceAuth

  helpers do
    def match_key(key)
      '34' == key
    end
  end

  get '/' do
    'ok'
  end
end

class TestSinatraRestServiceAuth < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    TestApp.new
  end

  def test_no_auth
    get '/'
    assert !last_response.ok?, "request should fail"
  end

  def test_auth_for_short_query
    q   = '?key=34'
    url = "http://example.org/#{q}"
    sig = Digest::SHA2.new(256).hexdigest(url)
    get "/#{q}&sig=#{sig}"
    assert last_response.ok?, "request should succeed"
  end

  def test_auth_for_long_query
    params = [%w{key 34}, %w{name John}, %w{age 32}, %w{city Honolulu}]
    q   = "?#{params.sort { |a, b| a.first <=> b.first }.map { |x| "#{x.first}=#{x.last}" }.join('&')}"
    url = "http://example.org/#{q}"
    sig = Digest::SHA2.new(256).hexdigest(url)
    get "/#{q}&sig=#{sig}"
    assert last_response.ok?, "request should succeed"
  end
end
