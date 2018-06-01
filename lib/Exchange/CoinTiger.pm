package Exchange::CoinTiger;
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
	    'id' => 'cointiger',
            'name' => 'CoinTiger',
            'countries' => 'AU', 
            'rateLimit' => 600, # no info
            'base_currency' => 'AUD',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
        'urls' => {
                'logo' => 'https://user-images.githubusercontent.com/1294454/29142911-0e1acfc2-7d5c-11e7-98c4-07d9532b29d7.jpg',
                'api'  => 'https://api.cointiger.com/',
                'www'  => 'https://www.cointiger.com/',
                'doc'  => 'https://github.com/cointiger/api-docs-en/wiki',
            },
            'can' => {
            	'rest'  => 1,
            	'push'  => 0,
            	'wsock' => 0
            },
            'fees' => {
                'trading' => {
                    'maker' => 0.0,
                    'taker' => 0.25 / 100,
                },
            },

        'symbols' => [
          {'id' => 'BTC/AUD'},
          {'id' => 'LTC/AUD'},
          {'id' => 'ETH/AUD'},
          {'id' => 'ETC/AUD'},
          {'id' => 'XRP/AUD'},
          {'id' => 'BCH/AUD'},
          {'id' => 'LTC/BTC'},
          {'id' => 'ETH/BTC'},
          {'id' => 'ETC/BTC'},
          {'id' => 'XRP/BTC'},
          {'id' => 'BCH/BTC'}
        ]
    },
}

sub ticker {
  my $self = shift;
  my %vars = @_;
  foreach my $symbol (@{$self->{config}->{symbols}}) {
    $self->get(
        url => "https://api.btcmarkets.net/market/$symbol->{id}/tick",
        on_result => sub { $self->process_ticker(@_) },
        on_error  => sub { $self->common_error(@_) },
      );
  }
}

sub ticker_ws {
  return 0; # https://socket.btcmarkets.net -- replies with error, API not working
  my $self = shift;
  my %vars = @_;
  
  my ($instrument, $currency) = split('/', $vars{symbol});

  my $request = {
     'instrument' => $instrument,
     'currency'   => $currency,
     'channelName' => 'Ticker-BTCMarkets-' . $instrument . "-" . $currency,
     'eventName' => 'newTicker'
    };


  $self->subscribe(
    url => 'https://socket.btcmarkets.net',
    request => encode_json $request,
    on_result => sub { $self->process_ticker(@_) },
    on_error  => sub { $self->common_error(@_, vars => { method => 'ws', symbol => $vars{symbol} }) },
  );
  
  
  
}

sub process_ticker {
  my $self = shift;
  my $tx = shift;
  my $ws_data = shift || undef;
  
  my %vars = @_;

  my $currency = $tx->result->json;
  $self->store_ticker(
      source		    => $self->config->{id},
      currency		  => $currency->{currency} . $currency->{instrument},
      status		    => 0, 
      date_ts		    => $currency->{timestamp},
      base_currency => $self->config->{base_currency},
      base_usd_rate	=> $self->usd_rates->{$self->config->{base_currency}}//1,
      highest_bid	  => $currency->{bestBid},
      lowest_ask	  => $currency->{bestAsk},
      opening_price	=> 0,
      closing_price	=> 0, 
      min_price		  => 0,
      max_price		  => 0,
      average_price	=> 0,
      units_traded	=> 0,
      volume_1day 	=> $currency->{volume24h},
      volume_7day	  => 0, 
    );
  return 1;
}


sub common_error {
  my $self = shift;
  $self->logger->info($_[0]);
}


1;
