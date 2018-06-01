package Exchange::Coinone;
use strict;
use warnings;

use parent 'Exchange';

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;
  $self->{config} = {
	    'id' => 'coinone',
            'name' => 'Coinone',
            'countries' => 'KR', 
            'rateLimit' => 90, # per minute
            'base_currency' => 'KRW',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
            'urls' => {
                'logo' => 'https://coinone.co.kr/static/img/coinone_logo_white_main.svg',
                'api' => 'https://api.coinone.co.kr/',
                'www' => 'https://coinone.co.kr/',
                'doc' => 'http://doc.coinone.co.kr',
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
    url => 'https://api.coinone.co.kr/ticker/?currency=all&format=json',
    on_result => sub { $self->process_ticker(@_) },
    on_error  => sub { $self->common_error(@_) },
  );

}

sub process_ticker {
  my $self = shift;
  my $tx = shift;

  my $currencies   	= $tx->result->json;


  foreach my $c (keys %$currencies) {
    my $currency = $currencies->{$c};

    if($c ne 'errorCode' && $c ne 'result' && $c ne 'timestamp'){
      $self->store_ticker(
        source    => $self->config->{id},
        currency    => $c,
        status    => $currencies->{errorCode}, # proper status for the ticker w/o errors
        date_ts   => $currencies->{timestamp},
        base_currency   => $self->config->{base_currency},
        base_usd_rate => $self->usd_rates->{$self->config->{base_currency}}//1,
        highest_bid => $currency->{last},
        lowest_ask  => $currency->{last},
        opening_price => $currency->{first},
        closing_price => $currency->{last}, 
        min_price   => $currency->{low},
        max_price   => $currency->{high},
        average_price => 0,
        units_traded  => 0,
        volume_1day => $currency->{volume},
        volume_7day => 0, 
      );
    }
  }

  return 1;
}

2;