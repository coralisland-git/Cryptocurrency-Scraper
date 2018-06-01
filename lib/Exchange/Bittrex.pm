package Exchange::Bittrex;
use strict;
use warnings;

use parent 'Exchange';
use JSON::XS qw{decode_json encode_json};

use Data::Dumper;
use Try::Tiny;
#use Time::Piece;
  
sub _init {
  my $self = shift;
  $self->{config} = {
	    'id' => 'bittrex',
            'name' => 'BitTrex',
            'countries' => 'US', 
            'rateLimit' => 500,
            'base_currency' => 'USD',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
            'urls' => {
                'logo' => 'https://bittrex.com/Content/img/logos/bittrex-logo-transparent.png',
                'api' => {
                    'public' => 'https://bittrex.com/home/api',
                    'private' => '',
                },
                'www' => 'https://bittrex.com/home',
                'doc' => '',
            },
            'can' => {
            	'rest'  => 1,
            	'push'  => 0,
            	'wsock' => 0,
            },
            'fees' => {
                'trading' => {
                    'maker' => 0.15 / 100,
                    'taker' => 0.15 / 100,
                },
            },
        'symbols' => $self->_get_symbols()
        

    },
}

sub ticker {
  my $self = shift;
  my %vars = @_;

  $self->get(
    url => 'https://bittrex.com/api/v1.1/public/getmarketsummaries',
    on_result => sub { $self->process_ticker(@_) },
    on_error  => sub { $self->common_error(@_) },
  );
}

sub ticker_ws {
  my $self = shift;
  my %vars = @_;
# No ws API available
}

sub process_ticker { 
  my $self = shift;
  my $tx = shift;
  
  foreach my $currency (@{$tx->result->json->{result}}) {
    $self->store_ticker(
        source		=> $self->config->{id},
        currency	=> $currency->{MarketName},
        status		=> 0, # proper status for the ticker w/o errors
        date_ts		=> $self->str2ts($currency->{TimeStamp}),
        base_currency 	=> $self->config->{base_currency},
        base_usd_rate	=> $self->usd_rates->{$self->config->{base_currency}}//1,
        highest_bid	=> $currency->{Bid},
        lowest_ask	=> $currency->{Ask},
        opening_price	=> 0,
        closing_price	=> $currency->{Last}, 
        min_price	=> $currency->{Low},
        max_price	=> $currency->{High},
        average_price	=> 0, #maybe can be calculated manually if not present?
        units_traded	=> 0,
        volume_1day	=> 0,
        volume_7day	=> 0, 
      );
   }
  return 1;
}


sub _get_symbols {
  my $self = shift;
  my $result =  decode_json $self->ua->get('https://bittrex.com/api/v1.1/public/getmarkets')->result->body;
  $result = $result->{result};  
  map {$_->{id} = delete $_->{MarketName}} @$result; # should be always named 'id' for using in loops
  
  return $result;
}

2;
