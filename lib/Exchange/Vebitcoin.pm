package Exchange::Vebitcoin;
use strict;
use warnings;

use parent 'Exchange';

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;
  $self->{config} = {
	    'id' => 'vebitcoin',
            'name' => 'Vebitcoin',
            'countries' => 'TU', 
            'rateLimit' => 500, # no info
            'base_currency' => 'USD',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
            'urls' => {
                'logo' => 'https://www.vebitcoin.com/Content/images/logo-2.png',
                'api' => 'https://www.vebitcoin.com/',
                'www' => 'https://www.vebitcoin.com/',
                'doc' => 'https://github.com/VebitcoinTeknoloji/tickers-api',
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
    url => 'https://www.vebitcoin.com/Ticker/All',
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
      currency    => $d->{Code},
      status    => 0, # proper status for the ticker w/o errors
      date_ts   => $self->str2ts($d->{Time}),
      base_currency   => $self->config->{base_currency},
      base_usd_rate => $self->usd_rates->{$self->config->{base_currency}}//1,
      highest_bid => $d->{Bid},
      lowest_ask  => $d->{Ask},
      opening_price => $d->{Open},
      closing_price => $d->{Last}, 
      min_price   => $d->{Low},
      max_price   => $d->{High},
      average_price => 0,
      units_traded  => 0,
      volume_1day => $d->{Volume},
      volume_7day => 0, 
    );
  }

  return 1;
}

2;


