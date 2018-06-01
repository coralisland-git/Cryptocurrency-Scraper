package Exchange::Coinbene;
use strict;
use warnings;

use parent 'Exchange';

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;
  $self->{config} = {
	    'id' => 'coinbene',
            'name' => 'Coinbene',
            'countries' => 'SP', 
            'rateLimit' => 500, # no info
            'base_currency' => 'USD',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
            'urls' => {
                'logo' => 'https://www.coinbene.com/static/img/logo-zh.6296e09.png',
                'api' => 'http://api.coinbene.com/v1/',
                'www' => 'https://www.coinbene.com/#/',
                'doc' => 'https://github.com/Coinbene/API-Documents-CHN/wiki/0.0.0-Coinbene-API文档',
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
    url => 'http://api.coinbene.com/v1/market/ticker?symbol=all',
    on_result => sub { $self->process_ticker(@_, id=>'btcusdt') },
    on_error  => sub { $self->common_error(@_) },
  );
}

sub process_ticker {
  my $self = shift;
  my $tx = shift;

  my $currencies   	= $tx->result->json->{ticker};
  my $timestamp     = $tx->result->json->{timestamp};

  foreach my $d (@{$currencies}) {
    if ($d->{bid} eq '--') {
      $d->{bid} = 0;
    }
    $self->store_ticker(
      source    => $self->config->{id},
      currency    => $d->{symbol},
      status    => 0, # proper status for the ticker w/o errors
      date_ts   => $timestamp / 1000,
      base_currency   => $self->config->{base_currency},
      base_usd_rate => $self->usd_rates->{$self->config->{base_currency}}//1,
      highest_bid => int($d->{bid} * 10000) / 10000,
      lowest_ask  => int($d->{ask} * 10000) / 10000,
      opening_price => 0,
      closing_price => $d->{last}, 
      min_price   => $d->{'24hrLow'},
      max_price   => $d->{'24hrHigh'},
      average_price => 0,
      units_traded  => 0,
      volume_1day => $d->{'24hrVol'},
      volume_7day => 0, 
    );
  }

  return 1;
}

2;


