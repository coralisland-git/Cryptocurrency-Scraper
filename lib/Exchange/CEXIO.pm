package Exchange::CEXIO;
use strict;
use warnings;

use parent 'Exchange';

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;
  $self->{config} = {
	    'id' => 'cexio',
            'name' => 'CEXIO',
            'countries' => 'UK', 
            'rateLimit' => 600, # per 10 minutes
            'base_currency' => 'USD',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
            'urls' => {
                'logo' => 'https://cex.io/img/cex_inner_header.svg',
                'api' => 'https://cex.io/api/',
                'www' => 'https://cex.io/',
                'doc' => 'https://cex.io/rest-api',
            },
            'can' => {
            	'rest'  => 1,
            	'push'  => undef,
            	'wsock' => undef,
            },
            'fees' => {
                'trading' => {
                    'maker' => 0.16 / 100,
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
      url => "https://cex.io/api/ticker/$symbol->{id}",
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
      date_ts   => $currency->{timestamp},
      base_currency   => $self->config->{base_currency},
      base_usd_rate => $self->usd_rates->{$self->config->{base_currency}}//1,
      highest_bid => $currency->{bid},
      lowest_ask  => $currency->{ask},
      opening_price => 0,
      closing_price => $currency->{last}, 
      min_price   => $currency->{low},
      max_price   => $currency->{high},
      average_price => 0,
      units_traded  => 0,
      volume_1day => $currency->{volume},
      volume_7day => 0, 
    );

  return 1;
}

sub _get_symbols {
  my $self = shift;
  my $result = $self->ua->get('https://cex.io/api/currency_limits')->result->json;
  my $new_result;
  $result = $result->{data}->{pairs};
  
  foreach (@$result) { # should be always named 'id' for using in loops
    my $currency = $_->{symbol1} . "/" . $_->{symbol2};
    next unless $self->symbol_allowed($currency) || $self->symbol_allowed('t'.$currency);
    push @{$new_result}, {id => $currency};
  }

  return $new_result;
}

2;