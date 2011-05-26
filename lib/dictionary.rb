require 'zlib'
require 'ap'

module LettersNumbers
  class Dictionary
    
    def initialize(new_word_file_path)
      @word_index = Hash.new{|h,i| h[i]=Array.new}
      @word_file_path = new_word_file_path
      load_word_file
    end
    
    def load_word_file
      File.open(@word_file_path,"r:ISO-8859-1") do |word_file|
        while line = word_file.gets
          add_word_to_dictionary(line_to_word(line))
        end
      end
    end
    
    def longest_valid_words(new_chars)
      results = Array.new
      new_chars.size.downto(1) do |i|
        new_chars.combination(i) do |char_combination|
          results.concat(chars_to_valid_words(char_combination)) if chars_contain_valid_words? char_combination
        end
        return results.uniq unless results.empty?
      end
      return results.uniq
    end
    
    def chars_to_valid_words(chars)
      return @word_index[array_to_index(chars)]
    end
    def chars_contain_valid_words?(chars)
      return false if @word_index[array_to_index(chars)].empty?
      return true
    end
    
    
    def word_exists?(word)
      return @word_index[word_to_index(word)].include?(word)
    end
    
    def add_word_to_dictionary(new_word)
      @word_index[word_to_index(new_word)].push(new_word)
    end
    
    def line_to_word(new_line)
      return Iconv.iconv("UTF-8", "ISO-8859-1",new_line.chomp)[0]
    end
    
    def array_to_index(new_array)
      return new_array.sort.inject(""){|result,char| result += char}
    end
    
    def word_to_index(new_word)
      return new_word.chars.sort.inject(""){|result,char| result += char}
    end
    
    def save(file_name)
      marshal_dump = Marshal.dump(self)
      file = File.new(file_name,'w')
      file = Zlib::GzipWriter.new(file)
      file.write marshal_dump
      file.close
    end
    
    def self.load(file_name)
      begin
        file = Zlib::GzipReader.open(file_name)
      rescue Zlib::GzipFile::Error
        file = File.open(file_name, 'r')
      ensure
        obj = Marshal.load file.read
        file.close
        return obj
      end
    end
    
    private :word_to_index, :array_to_index, :add_word_to_dictionary, :load_word_file
    
  end
end