package Exchange::GDAX;
use strict;
use warnings;

use parent 'Exchange';
use JSON::XS qw{decode_json encode_json};

use Data::Dumper;
use Try::Tiny;
#use Time::Piece;

sub _init {
  my $self = shift;
  $self->{channels} = {}; # store ws channel for each currency
  $self->{config} = {
	    'id' => 'gdax',
            'name' => 'GDAX',
            'countries' => 'US', 
            'rateLimit' => 500,
            'base_currency' => 'USD',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
        'urls' => {
                'logo' => 'https://user-images.githubusercontent.com/1294454/27766527-b1be41c6-5edb-11e7-95f6-5b496c469e2c.jpg',
                'api' => 'https://api.gdax.com',
                'www' => 'https://www.gdax.com',
                'doc' => 'https://docs.gdax.com',
            },
            'can' => {
            	'rest'  => 1,
            	'push'  => 0,
            	'wsock' => 1,
            },
            'fees' => {
                'trading' => {
                    'maker' => 0.0,
                    'taker' => 0.25 / 100,
                },
            },
        'symbols' => $self->_get_symbols()
    },
}

# sub ticker {
#   my $self = shift;
#   my %vars = @_;

#   foreach my $symbol (@{$self->{config}->{symbols}}) {
#     next unless $self->symbol_allowed($symbol->{id});
#     $self->get(
#       url => "https://api.gdax.com/products/$symbol->{id}/ticker",
#       on_result => sub { $self->process_ticker(@_, undef, id => $symbol->{id}) },
#       on_error  => sub { $self->common_error(@_) },
#     );
#   }
# }

sub ticker_ws {
  my $self = shift;
  my %vars = @_;
  
  my @all_symbols = @{$self->{config}->{symbols}};
  map {$_ = $_->{id}} grep {$self->symbol_allowed($_->{id})} @all_symbols;
  my $all_symbols_json = encode_json \@all_symbols;

  $self->logger->info($self->config->{id} .": subscribing to ws ticker feed");

  $self->subscribe(
    url => 'wss://ws-feed.gdax.com',
    reconnect_on_finish => 1,
    request => qq[{"type": "subscribe","channels": [{ "name": "ticker", "product_ids":  $all_symbols_json }]}],
    on_result => sub { $self->process_ticker(@_, id => 0) },
    on_error  => sub { $self->common_error(@_) },
  );
}

sub process_ticker { 
  my $self = shift;
  my $tx = shift;
  my $ws_data = shift || undef;
  my %vars = @_;
     

  my $currency;
  my $ws_currency = '';
  if(defined $ws_data) {
    $ws_data = decode_json $ws_data;
    if(defined $ws_data->{product_id}) {
      $vars{id} = $ws_data->{product_id};
      $currency = $ws_data;
    }
    else {return;}
  }
  else {
    $currency = $tx->result->json;
  }
  
  #my $time_stamp = substr($currency->{time},0, -8); #remove mseconds

  #my $t = Time::Piece->strptime($time_stamp, '%Y-%m-%dT%H:%M:%S');

  $self->store_ticker(
      source		=> $self->config->{id},
      currency		=> $vars{id},
      status		=> 0, # proper status for the ticker w/o errors
      date_ts		=> $currency->{time} ? $self->str2ts($currency->{time}) : time,
      base_currency 	=> $self->config->{base_currency},
      base_usd_rate	=> $self->usd_rates->{$self->config->{base_currency}}//1,
      highest_bid	=> $currency->{bid}//$currency->{best_bid},
      lowest_ask	=> $currency->{ask}//$currency->{best_ask},
      opening_price	=> $currency->{open_24h},
      closing_price	=> 0, 
      min_price		=> $currency->{low_24h},
      max_price		=> $currency->{high_24h}//$currency->{price},
      average_price	=> 0,
      units_traded	=> 0,
      volume_1day	=> $currency->{volume}//$currency->{volume_24h},
      volume_7day	=> 0, 
    );
  
  return 1;
}


sub _get_symbols {
  my $self = shift;
  my $result = decode_json $self->ua->get('https://api.gdax.com/products')->result->body;
  my $new_result;

  foreach (@$result) { # should be always named 'id' for using in loops
    next unless $self->symbol_allowed($_->{id});
    push @{$new_result}, {id => $_->{id}};
  }


  return $new_result;
}

2;
