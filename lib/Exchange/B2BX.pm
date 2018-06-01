package Exchange::B2BX;
use strict;
use warnings;

use parent 'Exchange';

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;
  $self->{config} = {
	    'id' => 'b2bx',
            'name' => 'B2BX',
            'countries' => 'CN', 
            'rateLimit' => 500, # no info
            'base_currency' => 'CNY',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
            'urls' => {
                'logo' => 'https://b2bx-demo.exchange/Content/themes/img/b2bx/dark/logo.png',
                'api' => 'https://api.lbank.info/v1/',
                'www' => 'https://www.lbank.info/',
                'doc' => 'https://www.lbank.info/api/',
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
    url => 'https://api.lbank.info/v1/ticker.do?symbol=all',
    on_result => sub { $self->process_ticker(@_) },
    on_error  => sub { $self->common_error(@_) },
  );
}

sub process_ticker {
  my $self = shift;
  my $tx = shift;

  my $currencies  	= $tx->result->json;
  foreach my $d (@{$currencies}) {

    $self->store_ticker(
      source    => $self->config->{id},
      currency    => $d->{symbol},
      status    => 0, # proper status for the ticker w/o errors
      date_ts   => $d->{timestamp}/1000,
      base_currency   => $self->config->{base_currency},
      base_usd_rate => $self->usd_rates->{$self->config->{base_currency}}//1,
      highest_bid => $d->{ticker}->{latest},
      lowest_ask  => $d->{ticker}->{latest},
      opening_price => 0,
      closing_price => $d->{ticker}->{latest}, 
      min_price   => $d->{ticker}->{low},
      max_price   => $d->{ticker}->{high},
      average_price => 0,
      units_traded  => 0,
      volume_1day => $d->{ticker}->{vol},
      volume_7day => 0, 
    );
  }

  return 1;
}

2;


