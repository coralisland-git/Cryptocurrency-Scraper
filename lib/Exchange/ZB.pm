package Exchange::ZB;
use strict;
use warnings;

use parent 'Exchange';
use JSON::XS qw{decode_json encode_json};

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;
  $self->{config} = {
      'id' => 'zb',
            'name' => 'ZB',
            'countries' => 'CN', 
            'rateLimit' => 500, # no info
            'base_currency' => 'CNY',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
            'urls' => {
                'logo' => 'https://s.zb.com/statics/img/v3/logo2018.png',
                'api' => 'Http://api.zb.com/data/v1', 
                'www' => 'https://www.zb.com/',
                'doc' => 'https://www.zb.com/i/developer',
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
            'symbols' => $self->_get_symbols()

    },
}


sub ticker {
  my $self = shift;
  my %vars = @_;

  foreach my $symbol (@{$self->{config}->{symbols}}) {
    next if !defined $symbol->{id};

    $self->get(
      url => "http://api.zb.com/data/v1/ticker?market=$symbol->{id}",
      on_result => sub { $self->process_ticker(@_, undef, id => $symbol->{id}) },
      on_error  => sub { $self->common_error(@_) },
    );
  }

}

sub process_ticker {
  my $self = shift;
  my $tx = shift;
  my ($tp1, $tp2, $curr) = (@_);

  my $currency    = $tx->result->json;

  $self->store_ticker(
      source    => $self->config->{id},
      currency    => $curr,
      status    => 0, # proper status for the ticker w/o errors
      date_ts   => $currency->{date} / 1000,
      base_currency   => $self->config->{base_currency},
      base_usd_rate => $self->usd_rates->{$self->config->{base_currency}}//1,
      highest_bid => $currency->{ticker}->{buy},
      lowest_ask  => $currency->{ticker}->{sell},
      opening_price => 0,
      closing_price => $currency->{ticker}->{last}, 
      min_price   => $currency->{ticker}->{low},
      max_price   => $currency->{ticker}->{high},
      average_price => 0,
      units_traded  => 0,
      volume_1day => $currency->{ticker}->{vol},
      volume_7day => 0, 
    );

  return 1;
}


sub _get_symbols {
  my $self = shift;
  my $result = $self->ua->get('http://api.zb.com/data/v1/markets')->result->json;
  my $new_result;
  
  foreach (keys %{$result}) { # should be always named 'id' for using in loops
    next unless $self->symbol_allowed($_) || $self->symbol_allowed('t'.$_);
    push @{$new_result}, {id => $_};
  }

  return $new_result;
}

2;
