package Exchange::WEX;
use strict;
use warnings;

use parent 'Exchange';

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;
  $self->{config} = {
	    'id' => 'wex',
            'name' => 'WEX',
            'countries' => {'US', 'BR', 'UK', 'IT', 'SG', 'AU'}, 
            'rateLimit' => 1, # every 2 seconds
            'base_currency' => 'USD',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
            'urls' => {
                'logo' => 'https://wex.nz/images/1px.png',
                'api' => 'https://wex.nz/api/3/',
                'www' => 'https://wex.nz',
                'doc' => 'https://wex.nz/api/3/docs',
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
        'symbols' => $self->_get_symbols()
    },
}

sub ticker {
  my $self = shift;
  my %vars = @_;

  foreach my $symbol (@{$self->{config}->{symbols}}) {
    next if !defined $symbol->{id};
    $self->get(
      url => "https://wex.nz/api/3/ticker/$symbol->{id}",
      on_result => sub { $self->process_ticker(@_, undef, id => $symbol->{id}) },
      on_error  => sub { $self->common_error(@_) },
    );
  }

}

sub process_ticker {
  my $self = shift;
  my $tx = shift;

  my $currency   	= $tx->result->json;
  foreach my $c (keys %$currency) {
    my $d = $currency->{$c};
    $self->store_ticker(
      source    => $self->config->{id},
      currency    => $c,
      status    => 0, # proper status for the ticker w/o errors
      date_ts   => $d->{updated},
      base_currency   => $self->config->{base_currency},
      base_usd_rate => $self->usd_rates->{$self->config->{base_currency}}//1,
      highest_bid => $d->{buy},
      lowest_ask  => $d->{sell},
      opening_price => 0,
      closing_price => $d->{last}, 
      min_price   => $d->{low},
      max_price   => $d->{high},
      average_price => $d->{avg},
      units_traded  => 0,
      volume_1day => $d->{vol_cur},
      volume_7day => $d->{vol}, 
    );
  }

  return 1;
}

sub _get_symbols {
  my $self = shift;
  my $result = $self->ua->get('https://wex.nz/api/3/info')->result->json;
  my $new_result;
  
  $result = $result->{pairs};  
  foreach (keys %{$result}) { # should be always named 'id' for using in loops
    next unless $self->symbol_allowed($_) || $self->symbol_allowed('t'.$_);
    push @{$new_result}, {id => $_};
  }

  return $new_result;
}

2;