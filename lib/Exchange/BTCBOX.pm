package Exchange::BTCBOX;
use strict;
use warnings;

use parent 'Exchange';
use JSON::XS qw{decode_json encode_json};

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;
  $self->{config} = {
	    'id' => 'btcbox',
            'name' => 'BTCBOX',
            'countries' => 'JP', 
            'rateLimit' => 500, # no info
            'base_currency' => 'JPY',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
        'urls' => {
                'logo' => 'https://www.btcbox.co.jp/images/jubi/logo.png',
                'api' => 'https://www.btcbox.co.jp/api/v1',
                'www' => 'https://www.btcbox.co.jp/',
                'doc' => 'https://www.btcbox.co.jp/api/doc/v1',
            },
            'can' => {
            	'rest'  => 1,
            	'push'  => 0,
            	'wsock' => 0,
            },
            'fees' => {
                'trading' => {
                    'maker' => 0.2 / 100,
                    'taker' => 0.2 / 100,
                },
            },
        'symbols' => [ # they have only a limited set of symbols
            {id => 'btc'},
            {id => 'ltc'},
            {id => 'eth'},
            {id => 'bch'}
         ]
    },
}

sub ticker {
  my $self = shift;
  my %vars = @_;


  foreach my $symbol ( @{$self->{config}->{symbols}}  ) {
    next unless $self->symbol_allowed($symbol->{id}) || $self->symbol_allowed('t'.$symbol->{id});
    $self->get(
      url => "https://www.btcbox.co.jp/api/v1/ticker?coin=$symbol->{id}",
      on_result => sub { $self->process_ticker(@_, id => $symbol->{id}) },
      on_error  => sub { $self->common_error(@_) },
    );
  }
}

sub ticker_ws {
  my $self = shift;
  my %vars = @_;
  die "No ws API available";
# No ws API available
}

sub process_ticker { 
  my $self = shift;
  my $tx = shift;
  my ($tp1, $curr ) = (@_);
   
  my $currency   	= $tx->result->json;

  $self->store_ticker(
      source		=> $self->config->{id},
      currency		=> $curr,
      status		=> 0, # proper status for the ticker w/o errors
      date_ts		=> time, # their timestamps seems to be with milliseconds
      base_currency   => $self->config->{base_currency},
      base_usd_rate => $self->usd_rates->{$self->config->{base_currency}}//1,
      highest_bid	=> $currency->{buy},
      lowest_ask	=> $currency->{sell},
      opening_price	=> 0,
      closing_price	=> $currency->{last}, 
      min_price		=> $currency->{low},
      max_price		=> $currency->{high},
      average_price	=> 0, 
      units_traded	=> 0,
      volume_1day	=> $currency->{vol},
      volume_7day	=> 0, 
    );

  return 1;
}


2;
