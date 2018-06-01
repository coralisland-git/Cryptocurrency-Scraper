package Exchange::OOOBTC;
use strict;
use warnings;

use parent 'Exchange';

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;
  $self->{config} = {
	    'id' => 'ooobtc',
            'name' => 'OOOBTC',
            'countries' => 'US', 
            'rateLimit' => 500, # no info
            'base_currency' => 'USD',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
            'urls' => {
                'logo' => 'https://www.ooobtc.com/assets/images/logo.png',
                'api' => 'https://api.ooobtc.com/',
                'www' => 'https://www.ooobtc.com/',
                'doc' => 'https://docs.api.ooobtc.com/',
            },
            'can' => {
            	'rest'  => 1,
            	'push'  => undef,
            	'wsock' => undef,
            },
            'fees' => {
                'trading' => {
                    'maker' => 0.25 / 100,
                    'taker' => 0.25 / 100,
                },
            },
    },
}

sub ticker {
  my $self = shift;
  my %vars = @_;

  $self->get(
    url => 'https://api.ooobtc.com/open/getallticker',
    on_result => sub { $self->process_ticker(@_) },
    on_error  => sub { $self->common_error(@_) },
  );
}

sub process_ticker {
  my $self = shift;
  my $tx = shift;

  my $res  	= $tx->result->json;
  my $currencies = delete $res->{data};

  foreach my $d (@{$currencies}) {

    $self->store_ticker(
      source    => $self->config->{id},
      currency    => $d->{tickername},
      status    => 0, # proper status for the ticker w/o errors
      date_ts   => $d->{timestamp},
      base_currency   => $self->config->{base_currency},
      base_usd_rate => $self->usd_rates->{$self->config->{base_currency}}//1,
      highest_bid => $d->{bid},
      lowest_ask  => $d->{ask},
      opening_price => 0,
      closing_price => $d->{lastprice}, 
      min_price   => 0,
      max_price   => 0,
      average_price => 0,
      units_traded  => 0,
      volume_1day => $d->{volume},
      volume_7day => 0, 
    );
  }

  return 1;
}

2;


