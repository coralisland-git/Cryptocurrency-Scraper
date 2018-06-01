package Exchange::Bitso;
use strict;
use warnings;

use parent 'Exchange';
use JSON::XS qw{decode_json encode_json};

use Data::Dumper;
use Try::Tiny;
use Time::Piece;

sub _init {
  my $self = shift;
  $self->{channels} = {}; # store ws channel for each currency
  $self->{config} = {
	    'id' => 'bitso',
            'name' => 'bitso',
            'countries' => 'MX', 
            'rateLimit' => 600, # per 10 minutes
            'base_currency' => 'EUR',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
        'urls' => {
                'logo' => 'https://user-images.githubusercontent.com/1294454/27786377-8c8ab57e-5fe9-11e7-8ea4-2b05b6bcceec.jpg',
                'api' => 'https://www.bitstamp.net/api',
                'www' => 'https://www.bitstamp.net',
                'doc' => 'https://www.bitstamp.net/api',
            },
            'can' => {
            	'rest'  => 1,
            	'push'  => 0,
            	'wsock' => 0,
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

sub ticker {
  my $self = shift;
  my %vars = @_;

  foreach my $symbol (@{$self->{config}->{symbols}}) {
    $self->get(
      url => "https://api.bitso.com/v3/ticker/?book=$symbol->{id}",
      on_result => sub { $self->process_ticker(@_, undef, id => $symbol->{id}) },
      on_error  => sub { $self->common_error(@_) },
    );
  }

}

sub ticker_ws {
  my $self = shift;
  my %vars = @_;
  

}

sub process_ticker {
  my $self = shift;
  my $tx = shift;
  my $ws_data = shift || undef;

  my %vars = @_;

  my $currency;
  my $ws_currency = '';
  my $time_stamp;
  if(defined $ws_data) {
    $ws_data = decode_json $ws_data;
    return if defined $ws_data->{ping};
    $currency = $ws_data->{data};
    $time_stamp = $currency->{timestamp};
    my $id = $ws_data->{id};
    $vars{id} = $self->{channels}->{$id};
  }
  else {
    $currency = $tx->result->json->{payload};
    $time_stamp = $self->str2ts(substr($currency->{created_at},0,-6)); 
  }
  
  
  $self->store_ticker(
      source		=> $self->config->{id},
      currency		=> $vars{id},
      status		=> 0, # proper status for the ticker w/o errors
      date_ts		=> $time_stamp,
      base_currency 	=> $self->config->{base_currency},
      base_usd_rate	=> $self->usd_rates->{$self->config->{base_currency}}//1,
      highest_bid	=> $currency->{bid},
      lowest_ask	=> $currency->{ask},
      opening_price	=> 0,
      closing_price	=> $currency->{last}, 
      min_price		=> $currency->{low},
      max_price		=> $currency->{high},
      average_price	=> 0,
      units_traded	=> $currency->{vwap},
      volume_1day	=> $currency->{volume},
      volume_7day	=> 0, 
    );
  
  return 1;
}


sub common_error {
  my $self = shift;
  $self->logger->info($_[0]);
}


sub _get_symbols {
  my $self = shift;
  my $result = decode_json $self->ua->get('https://api.bitso.com/v3/available_books/')->result->body;
  $result = $result->{payload};
  map {$_->{id} = delete $_->{book} } @{$result}; 

  return $result;
}


1;
