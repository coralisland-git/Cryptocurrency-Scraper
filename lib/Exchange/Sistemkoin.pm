package Exchange::Sistemkoin;
use strict;
use warnings;

use parent 'Exchange';

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;
  $self->{config} = {
	    'id' => 'sistemkoin',
            'name' => 'Sistemkoin',
            'countries' => 'TR', 
            'rateLimit' => 500, # no info
            'base_currency' => 'TRY',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
            'urls' => {
                'logo' => 'https://sistemkoin.com/assets/images/home/logo.png',
                'api' => 'https://sistemkoin.com/api/market/ticker',
                'www' => 'https://sistemkoin.com/',
                'doc' => '',
            },
            'can' => {
            	'rest'  => 1,
            	'push'  => undef,
            	'wsock' => undef,
            },
            'fees' => {
                'trading' => {
                    'maker' => 0.15 / 100,
                    'taker' => 0.15 / 100,
                },
            },
    },
}

sub ticker {
  my $self = shift;
  my %vars = @_;

  $self->get(
    url => 'https://sistemkoin.com/api/market/ticker',
    on_result => sub { $self->process_ticker(@_) },
    on_error  => sub { $self->common_error(@_) },
  );
}

sub process_ticker {
  my $self = shift;
  my $tx = shift;

  my $res  	= $tx->result->json;
  my $currencies = delete $res->{data};

  foreach my $c (keys %{$currencies}) {
    my $currency = $currencies->{$c};
    foreach my $d (@{$currency}) {
      $self->store_ticker(
        source    => $self->config->{id},
        currency    => $c . "/" . $d->{currency},
        status    => 0, # proper status for the ticker w/o errors
        date_ts   => time,
        base_currency   => $self->config->{base_currency},
        base_usd_rate => $self->usd_rates->{$self->config->{base_currency}}//1,
        highest_bid => $d->{bid},
        lowest_ask  => $d->{ask},
        opening_price => 0,
        closing_price => $d->{current}, 
        min_price   => $d->{low},
        max_price   => $d->{high},
        average_price => 0,
        units_traded  => 0,
        volume_1day => $d->{volume},
        volume_7day => 0, 
      );
    }
  }

  return 1;
}

2;


