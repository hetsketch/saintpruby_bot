require 'yaml'

require_relative './lib/commands/start'
require_relative './lib/commands/schedule'
require_relative './lib/commands/vote'
require_relative './lib/commands/speakers'
require_relative './lib/commands/jobs'
require_relative './lib/commands/beers'
require_relative './lib/commands/places'
require_relative './lib/commands/back'

# configuration = ROM::Configuration.new(:yaml, './data')
# configuration.register_relation(Relations::Jobs)
# configuration.register_relation(Relations::Talks)
# rom = ROM.container(configuration)

class Dispatcher

  SPEAKERS = File.read('./data/speakers.txt')
  UNKNOWN_COMMAND = 'undefined'.freeze
  UNKNOWN_RESPONSE = "Didn't get it".freeze

  def initialize(bot)
    @bot = bot
    bot_api = @bot.api
    @commands = {
      '/start' => Commands::Start.new(bot_api),
      '📆 Schedule' => Commands::Schedule.new(bot_api),
      '❤️ Vote' => Commands::Vote.new(bot_api),
      '🎤 Speakers' => Commands::Speakers.new(bot_api),
      '💵 Jobs' => Commands::Jobs.new(bot_api),
      '🍻 Beer counter' => Commands::Beers.new(bot_api),
      '🏛 Places' => Commands::Places.new(bot_api),
      '◀️ Back' => Commands::Back.new(bot_api)
    }
  end

  def call(message)
    case message
    when Telegram::Bot::Types::Message
      dispatch_message(message)
    when Telegram::Bot::Types::CallbackQuery
      dispatch_callback(message)
    end
  end

  private

  attr_reader :bot, :commands

  def dispatch_message(message)
    command = commands.fetch(message.text, UNKNOWN_COMMAND)
    return bot.api.send_message(chat_id: message.chat.id, text: UNKNOWN_RESPONSE) if command == UNKNOWN_COMMAND

    command.call(message)
  end

  def dispatch_callback(callback)
    begin
      command = JSON.parse(callback.data)['command']
    rescue JSON::ParserError
      bot.api.answer_callback_query(callback_query_id: callback.id, text: "I can't understand you")
    end

    if command == 'like'
      # redis.publish('liker_bot', message.from.username)
      bot.api.answer_callback_query(callback_query_id: callback.id)
    elsif command == 'more'
      Dispatchers::Job.new(bot).more(callback)
    end
  end
end
