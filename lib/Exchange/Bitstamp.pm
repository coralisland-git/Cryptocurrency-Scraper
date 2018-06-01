package Exchange::Bitstamp;
use strict;
use warnings;

use parent 'Exchange';

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;
  $self->{config} = {
	    'id' => 'bitstamp',
            'name' => 'Bitstamp',
            'countries' => 'LU', 
            'rateLimit' => 500, # no info
            'base_currency' => 'USD',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
            'urls' => {
                'logo' => 'https://www.bitstamp.net/s/images/Bitstamp_XS_cropped.png',
                'api' => 'https://www.bitstamp.net/api/v2/',
                'www' => 'https://www.bitstamp.net/',
                'doc' => 'https://www.bitstamp.net/api/',
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
      url => "https://www.bitstamp.net/api/v2/ticker/$symbol->{id}/",
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
      opening_price => $currency->{open},
      closing_price => $currency->{last}, 
      min_price   => $currency->{low},
      max_price   => $currency->{high},
      average_price => $currency->{vwap},
      units_traded  => 0,
      volume_1day => $currency->{volume},
      volume_7day => 0, 
    );

  return 1;
}

sub _get_symbols {
  my $self = shift;
  my $result = $self->ua->get('https://www.bitstamp.net/api/v2/trading-pairs-info/')->result->json;
  my $new_result;
  
  foreach (@$result) { # should be always named 'id' for using in loops
    next unless $self->symbol_allowed($_->{url_symbol}) || $self->symbol_allowed('t'.$_->{url_symbol});
    push @{$new_result}, {id => $_->{url_symbol}};
  }
  
  return $new_result;
}

2;