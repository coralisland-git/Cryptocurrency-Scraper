package Exchange::Bitz;
use strict;
use warnings;

use parent 'Exchange';

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;
  $self->{config} = {
	    'id' => 'bitz',
            'name' => 'Bitz',
            'countries' => 'HK', 
            'rateLimit' => 500,
            'base_currency' => 'USD',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
            'urls' => {
                'logo' => 'https://static.apiary.io/assets/1lqsC4I4.png',
                'api' => 'https://www.bit-z.com/api_v1/',
                'www' => 'https://www.bit-z.com',
                'doc' => 'https://www.bit-z.com/api.html',
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
    url => 'https://www.bit-z.com/api_v1/tickerall',
    on_result => sub { $self->process_ticker(@_) },
    on_error  => sub { $self->common_error(@_) },
  );
}

sub process_ticker {
  my $self = shift;
  my $tx = shift;

  my $res   	= $tx->result->json;
  my $status = delete $res->{code};
  my $currencies = delete $res->{data};
  foreach my $c (keys %$currencies) {
    my $d = $currencies->{$c};

    $self->store_ticker(
      source    => $self->config->{id},
      currency    => $c,
      status    => $status, # proper status for the ticker w/o errors
      date_ts   => $d->{date},
      base_currency   => $self->config->{base_currency},
      base_usd_rate => $self->usd_rates->{$self->config->{base_currency}}//1,
      highest_bid => $d->{buy},
      lowest_ask  => $d->{sell},
      opening_price => 0,
      closing_price => $d->{last}, 
      min_price   => $d->{low},
      max_price   => $d->{high},
      average_price => 0,
      units_traded  => 0,
      volume_1day => $d->{vol},
      volume_7day => 0, 
    );
  }

  return 1;
}

2;


