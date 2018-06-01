package Exchange::RightBTC;
use strict;
use warnings;

use parent 'Exchange';

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;
  $self->{config} = {
	    'id' => 'rightbtc',
            'name' => 'RightBTC',
            'countries' => 'AE', 
            'rateLimit' => 500, # no info
            'base_currency' => 'USD',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
            'urls' => {
                'logo' => 'https://www.rightbtc.com/assets/images/hftlogo@2x.png',
                'api' => 'https://www.rightbtc.com/api',
                'www' => 'https://www.rightbtc.com/',
                'doc' => 'https://www.rightbtc.com/api/public/',
            },
            'can' => {
            	'rest'  => 1,
            	'push'  => undef,
            	'wsock' => undef,
            },
            'fees' => {
                'trading' => {
                    'maker' => 0.2 / 100,
                    'taker' => 0.2 / 100,
                },
            },
    },
}

sub ticker {
  my $self = shift;
  my %vars = @_;

  $self->get(
    url => 'https://www.rightbtc.com/api/public/tickers',
    on_result => sub { $self->process_ticker(@_) },
    on_error  => sub { $self->common_error(@_) },
  );
}

sub process_ticker {
  my $self = shift;
  my $tx = shift;

  my $res  	= $tx->result->json;
  my $currencies = delete $res->{result};

  foreach my $d (@{$currencies}) {

    $self->store_ticker(
      source    => $self->config->{id},
      currency    => $d->{market},
      status    => 0, # proper status for the ticker w/o errors
      date_ts   => $d->{date} / 1000,
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
      volume_1day => $d->{vol24h},
      volume_7day => 0, 
    );
  }

  return 1;
}

2;


