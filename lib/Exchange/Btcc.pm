package Exchange::Btcc;
use strict;
use warnings;

use parent 'Exchange';

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;
  $self->{config} = {
	    'id' => 'btcc',
            'name' => 'Btcc',
            'countries' => 'UK', 
            'rateLimit' => 90, # per minute
            'base_currency' => 'USD',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
            'urls' => {
                'logo' => 'https://coinone.co.kr/static/img/coinone_logo_white_main.svg',
                'api' => 'https://spotusd-data.btcc.com/data/pro',
                'www' => 'https://www.btcc.com/',
                'doc' => 'https://www.btcc.com/apidocs',
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
    url => 'https://spotusd-data.btcc.com/data/pro/ticker?symbol=BTCUSD',
    on_result => sub { $self->process_ticker(@_, id => 'BTCUSD') },
    on_error  => sub { $self->common_error(@_) },
  );

}

sub process_ticker {
  my $self = shift;
  my $tx = shift;
  my ($tp1, $curr) = (@_);

  my $currency  	= $tx->result->json;

  foreach my $c (keys %$currency) {
    my $currency = $currency->{$c};
    $self->store_ticker(
        source    => $self->config->{id},
        currency    => $curr,
        status    => 0, # proper status for the ticker w/o errors
        date_ts   => $currency->{Timestamp} / 1000,
        base_currency   => $self->config->{base_currency},
        base_usd_rate => $self->usd_rates->{$self->config->{base_currency}}//1,
        highest_bid => $currency->{BidPrice},
        lowest_ask  => $currency->{AskPrice},
        opening_price => $currency->{Open},
        closing_price => $currency->{Last}, 
        min_price   => $currency->{Low},
        max_price   => $currency->{High},
        average_price => 0,
        units_traded  => 0,
        volume_1day => $currency->{Volume24H},
        volume_7day => 0, 
      );
  }

  return 1;
}

2;