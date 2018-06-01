package Exchange::Gopax;
use strict;
use warnings;

use parent 'Exchange';

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;
  $self->{config} = {
	    'id' => 'gopax',
            'name' => 'Gopax',
            'countries' => 'KR', 
            'rateLimit' => 500, # no info
            'base_currency' => 'KRW',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
            'urls' => {
                'logo' => 'https://www.gopax.co.kr/images/brand/logo-primary.svg',
                'api' => 'https://api.gopax.co.kr',
                'www' => 'https://www.gopax.co.kr',
                'doc' => 'https://www.gopax.co.kr/API/',
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
        'symbols' => $self->_get_symbols()
    },
}

sub ticker {
  my $self = shift;
  my %vars = @_;

  foreach my $symbol (@{$self->{config}->{symbols}}) {
    next if !defined $symbol->{id};

    $self->get(
      url => "https://api.gopax.co.kr/trading-pairs/$symbol->{id}/ticker",
      on_result => sub { $self->process_ticker(@_, undef, id => $symbol->{id}) },
      on_error  => sub { $self->common_error(@_) },
    );
  }

}

sub process_ticker {
  my $self = shift;
  my $tx = shift;
  my ($tp1, $tp2, $curr) = (@_);

  my $currency   	= $tx->result->json;

  $self->store_ticker(
      source    => $self->config->{id},
      currency    => $curr,
      status    => 0, # proper status for the ticker w/o errors
      date_ts   => $self->str2ts($currency->{time}),
      base_currency   => $self->config->{base_currency},
      base_usd_rate => $self->usd_rates->{$self->config->{base_currency}}//1,
      highest_bid => $currency->{bid},
      lowest_ask  => $currency->{ask},
      opening_price => 0,
      closing_price => $currency->{price}, 
      min_price   => $currency->{price},
      max_price   => $currency->{price},
      average_price => 0,
      units_traded  => 0,
      volume_1day => $currency->{volume},
      volume_7day => 0, 
    );

  return 1;
}

sub _get_symbols {
  my $self = shift;
  my $result = $self->ua->get('https://api.gopax.co.kr/trading-pairs/')->result->json;
  my $new_result;
  
  foreach (@$result) { # should be always named 'id' for using in loops
    next unless $self->symbol_allowed($_->{name}) || $self->symbol_allowed('t'.$_->{name});
    push @{$new_result}, {id => $_->{name}};
  }
  
  return $new_result;
}

2;