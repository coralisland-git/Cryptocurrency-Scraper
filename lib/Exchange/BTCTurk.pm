package Exchange::BTCTurk;
use strict;
use warnings;

use parent 'Exchange';

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;
  $self->{config} = {
	    'id' => 'btcturk',
            'name' => 'BTCTurk',
            'countries' => 'US', 
            'rateLimit' => 500, # no 
            'base_currency' => 'USD',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
            'urls' => {
                'logo' => 'https://www.btcturk.com/',
                'api' => 'https://www.btcturk.com/api/',
                'www' => 'https://www.btcturk.com/',
                'doc' => 'https://github.com/BTCTrader/broker-api-docs',
            },
            'can' => {
            	'rest'  => 1,
            	'push'  => undef,
            	'wsock' => undef,
            },
            'fees' => {
                'trading' => {
                    'maker' => 0.1 / 100,
                    'taker' => 0.1 / 100,
                },
            },
    },
}

sub ticker {
  my $self = shift;
  my %vars = @_;

  $self->get(
    url => 'https://www.btcturk.com/api/ticker',
    on_result => sub { $self->process_ticker(@_) },
    on_error  => sub { $self->common_error(@_) },
  );
}

sub process_ticker {
  my $self = shift;
  my $tx = shift;

  my $currencies   	= $tx->result->json;
  foreach my $d (@{$currencies}) {

    $self->store_ticker(
      source    => $self->config->{id},
      currency    => $d->{pair},
      status    => 0, # proper status for the ticker w/o errors
      date_ts   => $d->{timestamp},
      base_currency   => $self->config->{base_currency},
      base_usd_rate => $self->usd_rates->{$self->config->{base_currency}}//1,
      highest_bid => $d->{buy},
      lowest_ask  => $d->{sell},
      opening_price => $d->{open},
      closing_price => $d->{last}, 
      min_price   => $d->{low},
      max_price   => $d->{high},
      average_price => 0,
      units_traded  => 0,
      volume_1day => $d->{volume},
      volume_7day => 0, 
    );
  }

  return 1;
}

2;


