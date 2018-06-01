package Exchange::Gateio;
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
	    'id' => 'gateio',
            'name' => 'Gate.io',
            'countries' => 'CN', 
            'rateLimit' => 1000, #from ccxt
            'base_currency' => 'USDT',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
        'urls' => {
                'logo' => 'https://user-images.githubusercontent.com/1294454/31784029-0313c702-b509-11e7-9ccc-bc0da6a0e435.jpg',
                'api' => 'https://data.gate.io/api',
                'www' => 'https://gate.io/',
                'doc' => 'https://gate.io/api2',
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

  $self->get(
    url => 'http://data.gate.io/api2/1/tickers',
    on_result => sub { $self->process_ticker(@_) },
    on_error  => sub { $self->common_error(@_) },
  );

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
  my $currencies = $tx->result->json;
  foreach (keys %$currencies) {
    my $currency = $currencies->{$_};
    $self->store_ticker(
        source		    => $self->config->{id},
        currency		  => $_,
        status		    => 0,
        date_ts		    => time(),
        base_currency => $self->config->{base_currency},
        base_usd_rate	=> $self->usd_rates->{$self->config->{base_currency}}//1,
        highest_bid	  => $currency->{highestBid},
        lowest_ask	  => $currency->{lowestAsk},
        opening_price	=> 0,
        closing_price	=> $currency->{last}, 
        min_price		  => $currency->{low24hr},
        max_price		  => $currency->{high24hr},
        average_price	=> 0,
        units_traded	=> 0,
        volume_1day	  => $currency->{quoteVolume},
        volume_7day	  => 0, 
      );
  }
  return 1;
}


sub common_error {
  my $self = shift;
  $self->logger->info($_[0]);
}


sub _get_symbols {
  my $self = shift;
# as it returns all symbols in one request no need to get symbols available
  return 1;
}


1;
