require 'csv'

class Sorter

  def initialize
    @file_name = './data/movie_metadata.csv'
    @size_to_kb = {'KB' => 1, 'MB' => 1024, 'GB' => 1024*1024} # convert everything to KB in order compare sizes
  end

  def sort_by_genres
    genres = Hash.new { |hash, key| hash[key] = [] } # needed to avoid .has_key? check
    csv = CSV.new(File.read(@file_name), :headers => true)
    # sorting IMDB data in {'genre' => [{'title' => 'imbd_link'}, ...], ...} form
    csv.each do |row|
      movie = row.to_hash
      movie['genres'].split('|').each do |genre|
        if movie['imdb_score'].to_f > 7.0
          genres[genre].push(movie['movie_title'] => movie['movie_imdb_link'])
        end
      end
    end
    genres
  end

  def sort_by_torrent_size(search_result)
    sorted_by_size = search_result.sort_by do |torrent|
      size_raw = torrent[:size].split(' ')
      actual_size = size_raw[0].to_f
      units = size_raw[1]
      size_kb = actual_size * @size_to_kb[units]
    end
  end
end
