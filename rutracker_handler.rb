require 'dotenv/load'
require './sorter'
require './rutracker_api'

class RutrackerHandler

  def initialize
    @client = RutrackerApi.new(ENV['USERNAME'], ENV['PASSWORD'])
  end

  def get_torrend_url(movie)
    sorter = Sorter.new
    search_result = @client.search(term:movie.keys[0])
    unless search_result.is_a? Hash
      sorted_by_size = sorter.sort_by_torrent_size(search_result)
      torrent_id = sorted_by_size.last[:torrent_id]
      "https://rutracker.org/forum/viewtopic.php?t=#{torrent_id}"
    end
    "Oops! Can't find one"
  end
end
