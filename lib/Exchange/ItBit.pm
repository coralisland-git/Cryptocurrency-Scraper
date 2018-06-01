package Exchange::ItBit;
use strict;
use warnings;

use parent 'Exchange';

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;
  $self->{config} = {
	    'id' => 'itbit',
            'name' => 'ItBit',
            'countries' => 'US', 
            'rateLimit' => 500, # no info
            'base_currency' => 'USD',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
            'urls' => {
                'logo' => 'https://www.itbit.com/hubfs/itBit-Careers-Long.svg',
                'api' => 'https://api.itbit.com/v1/',
                'www' => 'https://www.itbit.com/',
                'doc' => 'https://api.itbit.com/docs',
            },
            'can' => {
            	'rest'  => 1,
            	'push'  => undef,
            	'wsock' => undef,
            },
            'fees' => {
                'trading' => {
                    'maker' => 0 / 100,
                    'taker' => 0.2 / 100,
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
      url => "https://api.itbit.com/v1/markets/$symbol->{id}/ticker",
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
      date_ts   => $self->str2ts($currency->{serverTimeUTC}),
      base_currency   => $self->config->{base_currency},
      base_usd_rate => $self->usd_rates->{$self->config->{base_currency}}//1,
      highest_bid => $currency->{bid},
      lowest_ask  => $currency->{ask},
      opening_price => $currency->{openToday},
      closing_price => $currency->{lastPrice}, 
      min_price   => $currency->{low24h},
      max_price   => $currency->{high24h},
      average_price => 0,
      units_traded  => 0,
      volume_1day => $currency->{volume24h},
      volume_7day => 0, 
    );

  return 1;
}

sub _get_symbols {
  my $self = shift;
  my @result = ('XBTUSD', 'XBTSGD', 'XBTEUR');
  my $new_result;
  
  foreach (@result) { # should be always named 'id' for using in loops
    next unless $self->symbol_allowed($_) || $self->symbol_allowed('t'.$_);
    push @{$new_result}, {id => $_};
  }
  
  return $new_result;
}

2;