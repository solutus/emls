require "sequel"
require "logger"
environment = ENV["RACK_ENV"] || "development"
require_relative "./config/#{environment}"
require_relative "emls"
Sequel.default_timezone = :utc
DB ||= Sequel.connect ConfigData[:db][:url]
Sequel::Model.db = DB
Dir.glob("models/*").map{ |file| require_relative file }


def development?
  ENV["RACK_ENV"] == "development"
end

def test?
  ENV["RACK_ENV"] == "test"
end
LOGGER = Logger.new(STDOUT)
LOGGER.level = Logger::WARN
if development?
  LOGGER.level = Logger::DEBUG
elsif test?
  LOGGER.level = Logger::FATAL
end
DB.loggers << LOGGER
