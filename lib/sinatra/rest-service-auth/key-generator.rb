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
				@keys = (1..@num_keys).map do |i|
					BCrypt::Password.create(srand)
				end

				@keys
			end
		end
	end
end
