require 'rubygems'
require 'bcrypt'

module Sinatra
	module RESTServiceAuth
		class KeyGenerator
			attr_reader :keys

			def initialize(num_keys=1)
				@num_keys = num_keys

				@keys = []
			end

			def generate_keys
				@num_keys.times do |i|
					@keys.push BCrypt::Password.create(srand)
				end

				self
			end
		end
	end
end
