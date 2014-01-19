require 'rubygems'
require 'sinatra'

configure :development do
  set :bind, '0.0.0.0'
  set :port, 3000
end

set :sessions, true

helpers do
  def calculate_total(cards) 
    arr = cards.map{|e| e[1] }
  
    total = 0
    arr.each do |value|
      if value == "A"
        total += 11
      elsif value.to_i == 0 # J, Q, K
        total += 10
      else
        total += value.to_i
      end
    end
  
    #correct for Aces
    arr.select{|e| e == "A"}.count.times do
      total -= 10 if total > 21
    end
  
    total
  end
  
  def card_image(card)
    suit = case card[0]
      when 'H' then 'hearts'
      when 'S' then 'spades'
      when 'C' then 'clubs'
      when 'D' then 'diamonds'
    end
                
    value = card[1]
    if ['J', 'Q', 'K', 'A'].include?(value)
      value = case card[1]
        when 'J' then 'jack'
        when 'Q' then 'queen'
        when 'K' then 'king'
        when 'A' then 'ace'
      end
    end
    
    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
  end
        
end

before do
  @hit_or_stay_buttons = true
end

get '/' do
  if session[:firstname]
    erb :game
  else
    redirect :'/new_user'
  end
end

get '/new_user' do
  erb :new_user
end

post '/player_name' do
  if params[:firstname].empty?
    @error = "Name is required"
    halt erb(:new_user)
  end
  session[:firstname] = params[:firstname]
  redirect '/game'
end

get '/game' do
  suits = ['H', 'D', 'S', 'C']
  cards = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  session[:deck] = suits.product(cards).shuffle!
  
  session[:dealercards] = []
  session[:playercards] = []
  session[:dealercards] << session[:deck].pop
  session[:playercards] << session[:deck].pop
  session[:dealercards] << session[:deck].pop
  session[:playercards] << session[:deck].pop

  erb :game
end

post '/game/player/hit' do
  session[:playercards] << session[:deck].pop
  player_total = calculate_total(session[:playercards])
  if player_total == 21
    @success = "Blackjack, #{session[:firstname]} has won!"
    @show_hit_or_stay_buttons = false
  elsif player_total > 21
    @error = "Sorry, it looks like you busted."
    @show_hit_or_stay_buttons = false
  end
  
  session[:playertotal] = calculate_total(session[:playercards])
  session[:dealertotal] = calculate_total(session[:dealercards])
  
  erb :game
end

post '/game/player/stay' do
  @success = "You have chosen to stay."
  @hit_or_stay_buttons = false
  
  session[:playertotal] = calculate_total(session[:playercards])
  session[:dealertotal] = calculate_total(session[:dealercards])
  
  redirect 'game/dealer'
end
      
get '/game/dealer' do
  @show_or_hit_buttons = false
  
  dealer_total = calculate_total(session[:dealercards])
  if dealer_total == 21
    @error = "Sorry, dealer hit blackjack!"
  elsif dealer_total > 21
    @success = "Congratulations, dealer busted, winner, winner!"
  elsif dealer_total >= 17
    redirect '/game/compare'
  else
    @show_dealer_hit_button = true
  end
  
  erb :game
end
      
post '/game/dealer/hit' do
  session[:dealercards] << session[:deck].pop
  redirect '/game/dealer'
end
      
get '/game/compare' do
  @show_or_hit_buttons = false
  
  player_total = calculate_total(session[:playercards])
  dealer_total = calculate_total(session[:dealercards])
  
  if dealer_total > player_total
    @error = "Sorry, dealer wins."
  elsif player_total > dealer_total
    @success = "Congratulations, you win!"
  else
    @error = "The worst, a push"
  end
  
  erb :game
end