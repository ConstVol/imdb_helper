require 'telegram/bot'
require 'csv'
require 'rutracker_api'

USERNAME = ''
PASSWORD = ''
TOKEN    = ''

size_to_kb = {'KB' => 1, 'MB' => 1024, 'GB' => 1024*1024} # convert everything to KB in order compare sizes
client = RutrackerApi.new(USERNAME, PASSWORD)

genres = sort_by_genres # sort imdb data by movie genre
# create array of telegram buttons, one for each genre
buttons = []
genres.keys.each { |genre| buttons << Telegram::Bot::Types::InlineKeyboardButton.new(text: genre, callback_data: genre)}

Telegram::Bot::Client.run(TOKEN) do |bot|

  bot.listen do |message|

    case
      when message.is_a?(Telegram::Bot::Types::CallbackQuery)

        movie = genres[message.data].sample # get random movie by genre in ['title' => 'imdb_link'] form
        search_result = client.search(term:movie.keys[0])

        #searching on rutracker by movie title(checking if response isn't {:error => 'Not found'}) -> sorting response by size -> getting the last one(biggest one)
        torrent_id = client.search(term:movie.keys[0]).sort_by{|torrent| torrent[:size].split(" ")[0].to_f * size_to_kb[torrent[:size].split(" ")[1]]}.last[:torrent_id] unless search_result.is_a? Hash
        torrent_url = search_result.is_a?(Hash) ? "Oops! Can't find one" : "https://rutracker.org/forum/viewtopic.php?t=#{torrent_id}"

        # sending imdb link and rutracker link if we got one
        bot.api.send_message(chat_id: message.from.id, text: "Here is my recommendation \n#{movie.values[0]}\nProbably you can download it here: #{torrent_url}")
      when message.text == "/start"

        markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: buttons)
        bot.api.send_message(chat_id: message.chat.id, text: 'What do you wanna watch tonight?', reply_markup: markup)
    end
  end
end

def sort_by_genres

  genres = Hash.new { |hash, key| hash[key] = [] } # needed to avoid .has_key? check
  csv = CSV.new(File.read('./data/movie_metadata.csv'), :headers => true)

# sorting IMDB data in {'genre' => [{'title' => 'imbd_link'}, ...], ...} form
  csv.each do |row|
    movie = row.to_hash
    movie['genres'].split('|').each do|genre|
      if movie['imdb_score'].to_f > 7
        genres[genre].push(movie['movie_title'] => movie['movie_imdb_link'])
      end
    end
  end
  genres
end
