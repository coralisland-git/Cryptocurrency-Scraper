package Exchange::Zebpay;
use strict;
use warnings;

use parent 'Exchange';

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;
  $self->{config} = {
	    'id' => 'zebpay',
            'name' => 'Zebpay',
            'countries' => 'IN', 
            'rateLimit' => 500, # no info
            'base_currency' => 'INR',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
            'urls' => {
                'logo' => 'https://www.zebpay.com/wp-content/uploads/2015/12/zebpay-retina-logo.png',
                'api' => 'https://www.zebapi.com/api/v1/',
                'www' => 'https://www.zebpay.com/',
                'doc' => 'https://support.zebpay.com/hc/en-us/articles/115004228609-Zebpay-APIs',
            },
            'can' => {
            	'rest'  => 1,
            	'push'  => undef,
            	'wsock' => undef,
            },
            'fees' => {
                'trading' => {
                    'maker' => 0.2 / 100,
                    'taker' => 0.25 / 100,
                },
            },
        'symbols' => $self->_get_symbols()
    },
}

sub ticker {
  my $self = shift;
  my %vars = @_;

  foreach my $symbol (@{$self->{config}->{symbols}}) {
    next if !defined $symbol->{id};
    $self->get(
      url => "https://www.zebapi.com/api/v1/market/ticker-new/$symbol->{id}/inr",
      on_result => sub { $self->process_ticker(@_, undef, id => $symbol->{id}) },
      on_error  => sub { $self->common_error(@_) },
    );
  }

}

sub process_ticker {
  my $self = shift;
  my $tx = shift;

  my $currency   	= $tx->result->json;
  $self->store_ticker(
      source    => $self->config->{id},
      currency    => $currency->{pair},
      status    => 0, # proper status for the ticker w/o errors
      date_ts   => time,
      base_currency   => $self->config->{base_currency},
      base_usd_rate => $self->usd_rates->{$self->config->{base_currency}}//1,
      highest_bid => $currency->{buy},
      lowest_ask  => $currency->{sell},
      opening_price => 0,
      closing_price => 0, 
      min_price   => $currency->{'24hoursLow'},
      max_price   => $currency->{'24hoursHigh'},
      average_price => 0,
      units_traded  => 0,
      volume_1day => $currency->{volume},
      volume_7day => 0, 
    );

  return 1;
}

sub _get_symbols {
  my $self = shift;
  my %currencies = ('btc', 'eth', 'bch', 'ltc', 'xrp', 'eos');
  my $new_result;
   
  foreach (%currencies) { # should be always named 'id' for using in loops
    next unless $self->symbol_allowed($_) || $self->symbol_allowed('t'.$_);
    push @{$new_result}, {id => $_};
  }

  return $new_result;
}

2;