#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'

# run Hangman.new to play Hangman in CLI
class Hangman
  attr_accessor :running_result, :letters_guessed, :remaining_attempts
  attr_reader :length, :word

  def initialize
    welcome
    load_or_new
    puts "\nAlright, let's play!\n\n"
    print_current_state
    play_round
  end

  private

  def welcome
    puts "\n- - -   H A N G M A N   - - -\n\n"
  end

  def load_or_new
    user_input(/^[ynYN]$/, LOAD_OR_NEW).downcase == 'y' ? load_game : new_game
  end

  def new_game
    length = user_input(/^[rR]$|^[5-9]$|^1[012]$/, LENGTH)
    @length = (length.downcase == 'r' ? rand(5..12) : length.to_i)
    @word = search_word.downcase
    @running_result = Array.new(word.length, ' _ ')
    @letters_guessed = []
    @remaining_attempts = 6
  end

  def load_game
    file = YAML.safe_load(File.read("saves/#{filename}"))
    @word = file['word']
    @running_result = file['running_result']
    @letters_guessed = file['letters_guessed']
    @remaining_attempts = file['remaining_attempts']
  rescue StandardError
    puts "\nLoading files: failed.\n\n"
    ask_for_restart
  end

  def filename
    saves_list.each { |k, v| puts "#{k}: #{v[0..-6]}" }
    file_number = user_input(/^[1-#{saves_list.length}]$/, PICK_FILE).to_i
    saves_list[file_number]
  end

  def saves_list
    saves = {}
    Dir.entries('saves').sort.reverse.each_with_index do |filename, index|
      saves[index + 1] = filename unless filename.match(/^\.+$/) || index > 8
    end
    saves
  end

  def play_round(attemp = '')
    loop do
      attemp = user_input(/^[a-zA-Z]$|^save$|^SAVE$/, GUESS).downcase
      letters_guessed.include?(attemp) ? print(TRIED_ALREADY) : break
    end
    update_game(attemp)
  end

  def update_game(attemp)
    if attemp == 'save'
      save
      continue_or_exit
    else
      update_letters_guessed(attemp)
      update_running_result(attemp)
    end
    print_current_state
    up_next
  end

  def update_running_result(char)
    if word.include?(char)
      puts "\nHit!"
      word.split('').each_with_index do |n, index|
        running_result[index] = " #{char.upcase} " if n == char
      end
    else
      puts "\nNope."
      @remaining_attempts -= 1
    end
  end

  def save
    filename = "hangman_save_#{Time.now.strftime('%d.%m.%y_%k:%M:%S')}.yaml"
    Dir.mkdir 'saves' unless Dir.exist? 'saves'
    File.open("saves/#{filename}", 'w') { |file| file.write state_to_yaml }
  end

  def state_to_yaml
    YAML.dump(
      'word' => @word,
      'running_result' => @running_result,
      'letters_guessed' => @letters_guessed,
      'remaining_attempts' => @remaining_attempts
    )
  end

  def up_next
    if game_over?
      puts "Victory!\n\n" if victory?
      puts "Defeat. It was #{word}.\n\n" if defeat?
      ask_for_restart
    else
      play_round
    end
  end

  def update_letters_guessed(char)
    @letters_guessed << char
  end

  def game_over?
    victory? || defeat?
  end

  def victory?
    running_result.count(' _ ').zero?
  end

  def defeat?
    remaining_attempts.zero?
  end

  def ask_for_restart
    user_input(/^[ynYN]$/, RESTART).downcase == 'y' ? initialize : exit
  end

  def continue_or_exit
    ask_for_restart if user_input(/^[ynYN]$/, CONTINUE).downcase == 'n'
  end

  def print_current_state
    puts "#{running_result.join.ljust(running_result.length * 3 + 5)}"\
    "remaining attempts: #{remaining_attempts}     "\
    "#{letters_guessed.length.zero? ? '' : 'already guessed: '}"\
    "#{letters_guessed.join(', ')}\n\n"
  end

  def search_word
    file = File.read('5desk.txt').split(/\r\n/).select do |str|
      str.length == length
    end
    file[rand(file.length)]
  end

  def user_input(regex, prompt)
    print '> '
    loop do
      print prompt
      input = gets.chomp
      input.match(regex) ? (return input) : print("\n> INVALID: ")
    end
  end

  LOAD_OR_NEW = "choose if you want to load a saved game
y = yes
n = no
> decide: "

  GUESS = "guess (or type 'save' to save the game)!
> a -z: "

  TRIED_ALREADY = "You tried this already, go for someting else!\n"

  LENGTH = "Please choose length of the word to guess.
  It can be between 5 and 12, or type \'R\' for a random length.
> length: "

  RESTART = "choose if you want to play again
y = yes
n = no
> decide: "

  CONTINUE = "choose if you want to continue
y = yes
n = no
> decide: "

  PICK_FILE = "choose file to load
> file-nr: "
end

Hangman.new
