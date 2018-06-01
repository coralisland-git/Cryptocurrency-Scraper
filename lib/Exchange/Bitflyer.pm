package Exchange::Bitflyer;
use strict;
use warnings;

use parent 'Exchange';
use JSON::XS qw{decode_json encode_json};

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;
  $self->{channels} = {}; # store ws channel for each currency
  $self->{config} = {
	    'id' => 'bitflyer',
            'name' => 'Bitflyer',
            'countries' => 'JP', 
            'rateLimit' => 500,
            'base_currency' => 'JPY',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
        'urls' => {
                'logo' => 'https://user-images.githubusercontent.com/1294454/28051642-56154182-660e-11e7-9b0d-6042d1e6edd8.jpg',
                'api' => 'https://api.bitflyer.jp',
                'www' => 'https://bitflyer.jp',
                'doc' => 'https://bitflyer.jp/API',
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
    next if !defined $symbol->{id};
    $self->get(
      url => "https://api.bitflyer.jp/v1/ticker?product_code=$symbol->{id}",
      on_result => sub { $self->process_ticker(@_, undef, id => $symbol->{id}) },
      on_error  => sub { $self->common_error(@_) },
    );
  }

}

sub ticker_ws {
  my $self = shift;
  my %vars = @_;
  
# no ws support
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
 #they use another API for real-time data, maybe complete later
  }
  else {
    $currency = $tx->result->json;

    $time_stamp = $self->str2ts($currency->{timestamp});
  }
  
  
  $self->store_ticker(
      source		=> $self->config->{id},
      currency		=> $vars{id},
      status		=> 0, # proper status for the ticker w/o errors
      date_ts		=> $time_stamp,
      base_currency 	=> $self->config->{base_currency},
      base_usd_rate	=> $self->usd_rates->{$self->config->{base_currency}}//1,
      highest_bid	=> $currency->{best_bid},
      lowest_ask	=> $currency->{best_ask},
      opening_price	=> 0,
      closing_price	=> 0, 
      min_price		=> 0,
      max_price		=> 0,
      average_price	=> 0,
      units_traded	=> 0,
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
  my $result = decode_json $self->ua->get('https://api.bitflyer.jp/v1/markets')->result->body;
  
  map {$_->{id} = length $_->{'product_code'} == 7 ? $_->{'product_code'} : undef } @$result; # remove unneeded symbols like `BTCJPY16FEB2018`

  return $result;
}


1;
