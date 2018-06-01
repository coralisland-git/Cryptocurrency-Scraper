package Exchange::Quoine;
use strict;
use warnings;

use parent 'Exchange';

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;
  $self->{config} = {
	    'id' => 'quoine',
            'name' => 'Quoine',
            'countries' => 'CN', 
            'rateLimit' => 300, # per 5 min
            'base_currency' => 'JPY',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
            'urls' => {
                'logo' => 'https://quoine.com/f3fb259e935db7d9e4b7c7dabd0c9f22.svg',
                'api' => 'https://api.quoine.com/',
                'www' => 'https://quoine.com/',
                'doc' => 'https://developers.quoine.com/',
            },
            'can' => {
            	'rest'  => 1,
            	'push'  => undef,
            	'wsock' => undef,
            },
            'fees' => {
                'trading' => {
                    'maker' => 0,
                    'taker' => 0,
                },
            },
    },
}

sub ticker {
  my $self = shift;
  my %vars = @_;

  $self->get(
    url => 'https://api.quoine.com/products',
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
      currency    => $d->{currency_pair_code},
      status    => 0, # proper status for the ticker w/o errors
      date_ts   => time,
      base_currency   => $self->config->{base_currency},
      base_usd_rate => $self->usd_rates->{$self->config->{base_currency}}//1,
      highest_bid => $d->{market_bid},
      lowest_ask  => $d->{market_ask},
      opening_price => 0,
      closing_price => $d->{last_price_24h}, 
      min_price   => $d->{low_market_bid},
      max_price   => $d->{high_market_ask},
      average_price => 0,
      units_traded  => 0,
      volume_1day => 0,
      volume_7day => 0, 
    );
  }

  return 1;
}

2;


