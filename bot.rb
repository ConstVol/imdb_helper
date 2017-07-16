require 'telegram/bot'
require 'dotenv/load'
require './sorter'
require './rutracker_handler'

sorter = Sorter.new
rutracker_handler = RutrackerHandler.new
genres = sorter.sort_by_genres # sort imdb data by movie genre
buttons = [] # create array of telegram buttons, one for each genre
genres.keys.each { |genre| buttons << Telegram::Bot::Types::InlineKeyboardButton.new(text: genre, callback_data: genre) }
Telegram::Bot::Client.run(ENV['TOKEN']) do |bot|
  bot.listen do |message|
    case
      when message.is_a?(Telegram::Bot::Types::CallbackQuery)
        movie = genres[message.data].sample # get random movie by genre in ['title' => 'imdb_link'] form
        torrent_url = rutracker_handler.get_torrend_url(movie)
        # sending imdb link and rutracker link if we got one
        bot.api.send_message(chat_id: message.from.id, text: "Here is my recommendation \n#{movie.values[0]}\nProbably you can download it here: #{torrent_url}")
      when message.text == "/start"
        markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: buttons)
        bot.api.send_message(chat_id: message.chat.id, text: 'What do you wanna watch tonight?', reply_markup: markup)
    end
  end
end
