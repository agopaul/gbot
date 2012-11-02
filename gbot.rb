require 'rubygems'
require 'sinatra'
require 'easy-gtalk-bot'
require 'json'
require 'logging'
require 'yaml'

$path = File.expand_path(File.dirname(__FILE__))

class GBot < Sinatra::Base

	@config = YAML.load_file("config.yml")

	@logger = Logging.logger['gbot']

	@logger.add_appenders(
		Logging.appenders.stdout,
		Logging.appenders.file("#{$path}/gbot.log")
	)

	@enable_bot = true

	if @enable_bot
		@bot = GTalk::Bot.new(:email => @config["bot"]["email"], :password => @config["bot"]["password"])
		@bot.get_online

		@bot.on_message do |from, text|
			@logger.debug "I got message from #{from}: '#{text}'"
			response = "Minchia vuoi?"

			@bot.message from, response
			@logger.debug "Auto-response to #{from} '#{response}'"
		end

		@logger.info "gbot ready"
	end

	configure do
		set :bind, @config["http"]["bind"]
		set :port, @config["http"]["port"]
		set :app, @config
		set :logger, @logger
		set :bot, @bot
	end

	post '/api/v1/message', :provides => :json do
		content_type :json

		if params[:apikey] == settings.app["http"]["apikey"]

			settings.app["bot"]["admins"].each do |user|
				body = params[:body]

				settings.logger.debug "Sending '#{body}' to #{user}"

				settings.bot.message user, body
			end

			status 201
			{'status' => 'ok'}.to_json

		else
			status 403
			{'error' => 'Invalid API key'}.to_json
		end		
	end

end

# Little dirty hack
GBot.run!
exit