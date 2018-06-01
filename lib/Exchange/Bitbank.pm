package Exchange::Bitbank;
use strict;
use warnings;

use parent 'Exchange';
use JSON::XS qw{decode_json encode_json};

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;
  $self->{config} = {
	    'id' => 'bitbank',
            'name' => 'Bitbank',
            'countries' => 'Japan', 
            'rateLimit' => 500,
            'base_currency' => 'JPY',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
        'urls' => {
                'logo' => 'https://docs.bitbank.cc/images/bitbankcc_api_logo_w.svg',
                'api' => 'https://public.bitbank.cc',
                'www' => 'https://bitbank.cc/',
                'doc' => 'https://docs.bitbank.cc/#/Ticker',
            },
            'can' => {
            	'rest'  => 1,
            	'push'  => 0,
            	'wsock' => 0,
            },
            'fees' => {
                'trading' => {
                    'maker' => 0.15 / 100,
                    'taker' => 0.15 / 100,
                },
            },
        'symbols' => [ # they have only a limited set of symbols
            {id => 'btc_jpy'},
            {id => 'xrp_jpy'},
            {id => 'ltc_btc'},
            {id => 'eth_btc'},
            {id => 'mona_jpy'},
            {id => 'mona_btc'},
            {id => 'bcc_jpy'},
            {id => 'bcc_btc'}
         ]
    },
}

sub ticker {
  my $self = shift;
  my %vars = @_;


  foreach my $symbol ( @{$self->{config}->{symbols}}  ) {
    next unless $self->symbol_allowed($symbol->{id});
    $self->get(
      url => "https://public.bitbank.cc/$symbol->{id}/ticker",
      on_result => sub { $self->process_ticker(@_,id => $symbol->{id}) },
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
  my %vars = @_;
   
  my $currency   	= $tx->result->json->{data};
  my $base_currency	= $self->config->{base_currency};

  $self->store_ticker(
      source		=> $self->config->{id},
      currency		=> $vars{id},
      status		=> 0, # proper status for the ticker w/o errors
      date_ts		=> substr($currency->{timestamp}, 0, -3), # their timestamps seems to be with milliseconds
      base_currency 	=> $base_currency,
      base_usd_rate	=> $vars{id}=~m/$base_currency/is ? $self->usd_rates->{ $base_currency }//1 : 1, # not to apply exchange rates to coin/coin pairs, should be moved to the base module
      highest_bid	=> $currency->{buy},
      lowest_ask	=> $currency->{sell},
      opening_price	=> 0,
      closing_price	=> $currency->{last}, 
      min_price		=> $currency->{low},
      max_price		=> $currency->{high},
      average_price	=> 0, #maybe can be calculated manually if not present?
      units_traded	=> 0,
      volume_1day	=> 0,
      volume_7day	=> 0, 
    );

  return 1;
}


2;
