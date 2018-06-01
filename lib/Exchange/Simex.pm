package Exchange::Simex;
use strict;
use warnings;

use parent 'Exchange';

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;
  $self->{config} = {
	    'id' => 'simex',
            'name' => 'Simex',
            'countries' => 'RU', 
            'rateLimit' => 500, # no info
            'base_currency' => 'RUB',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
            'urls' => {
                'logo' => 'https://ucarecdn.com/adf7187e-f066-40a7-937b-b2367b11906a/-/resize/280x/',
                'api' => 'https://simex.global/api',
                'www' => 'https://simex.global',
                'doc' => 'https://simex.global/en/docs/introduction',
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
    url => 'https://simex.global/api/pairs',
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
      currency    => $d->{base}->{name} . "/" . $d->{quote}->{name},
      status    => 0, # proper status for the ticker w/o errors
      date_ts   => time,
      base_currency   => $self->config->{base_currency},
      base_usd_rate => $self->usd_rates->{$self->config->{base_currency}}//1,
      highest_bid => $d->{buy_price},
      lowest_ask  => $d->{sell_price},
      opening_price => 0,
      closing_price => $d->{last_price}, 
      min_price   => $d->{low_price},
      max_price   => $d->{high_price},
      average_price => 0,
      units_traded  => 0,
      volume_1day => $d->{quote_volume},
      volume_7day => 0, 
    );
  }

  return 1;
}

2;


