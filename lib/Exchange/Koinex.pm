package Exchange::Koinex;
use strict;
use warnings;

use parent 'Exchange';
use JSON::XS qw{decode_json encode_json};

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;

  $self->{config} = {
	    'id' => 'koinex',
            'name' => 'Koinex',
            'countries' => 'IN', 
            'rateLimit' => 600, # no info
            'base_currency' => 'INR',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
        'urls' => {
                'logo' => 'https://koinex.in/koinex-logo-new.jpeg',
                'api'  => 'https://koinex.in/api/ticker',
                'www'  => 'https://koinex.in',
            },
            'can' => {
            	'rest'  => 1,
            	'push'  => 0,
            	'wsock' => 0,
            },
            'fees' => {
                'trading' => {
                    'maker' => 0.0,
                    'taker' => 0.25 / 100,
                },
            },

        'symbols' => $self->_get_symbols()
    },
}

sub ticker {
  my $self = shift;
  my %vars = @_;

  $self->get(
      url => 'https://koinex.in/api/ticker',
      on_result => sub { $self->process_ticker(@_) },
      on_error  => sub { $self->common_error(@_) },
    );
}

sub ticker_ws {
  my $self = shift;
  my %vars = @_;
}

sub process_ticker {
  my $self = shift;
  my $tx = shift;
  my %vars = @_;

  my $currencies = $tx->result->json->{stats};
  foreach (keys %$currencies) {  
    my $currency = $currencies->{$_};
    $self->store_ticker(
        source		=> $self->config->{id},
        currency		=> $_,
        status		=> 0, 
        date_ts		=> time(),
        base_currency 	=> $self->config->{base_currency},
        base_usd_rate	=> $self->usd_rates->{$self->config->{base_currency}}//1,
        highest_bid	=> $currency->{highest_bid},
        lowest_ask	=> $currency->{lowest_ask},
        opening_price	=> 0,
        closing_price	=> $currency->{last}, 
        min_price		=> $currency->{min_24hrs},
        max_price		=> $currency->{max_24hrs},
        average_price	=> 0,
        units_traded	=> 0,
        volume_1day	=> $currency->{vol_24hrs},
        volume_7day	=> 0, 
      );
  }
  return 1;
}


sub common_error {
  my $self = shift;
  $self->logger->info($_[0]);
}


sub _get_symbols {
  my $self = shift;

  return 1;
}


1;
