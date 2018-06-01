package Exchange::Poloniex;
use strict;
use warnings;

use parent 'Exchange';

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;
  $self->{config} = {
	    'id' => 'poloniex',
            'name' => 'Poloniex',
            'countries' => 'US', 
            'rateLimit' => 1000,
            'base_currency' => 'USD',
            'has' => {
	      	'createDepositAddress' => 1,
                'fetchDepositAddress' => 1,
                'CORS' => 1,
                'fetchOHLCV' => 1,
                'fetchMyTrades' => 1,
                'fetchOrder' => 'emulated',
                'fetchOrders' => 'emulated',
                'fetchOpenOrders' => 1,
                'fetchClosedOrders' => 'emulated',
                'fetchTickers' => 1,
                'fetchCurrencies' => 1,
		'withdraw' => 1,
            },
            'urls' => {
                'logo' => 'https://user-images.githubusercontent.com/1294454/27766817-e9456312-5ee6-11e7-9b3c-b628ca5626a5.jpg',
                'api'  => {
                    'public'  => 'https://poloniex.com/public',
                    'private' => 'https://poloniex.com/tradingApi',
                },
                'www' => 'https://poloniex.com',
                'doc' => [
                    'https://poloniex.com/support/api/',
                    'http://pastebin.com/dMX7mZE0',
                ],
		'fees' => 'https://poloniex.com/fees',
            },
            'can' => {
            	'rest'  => 1,
            	'push'  => undef,
            	'wsock' => undef,
            },
            'fees' => {
                'trading' => {
		  'maker' => 0.0015,
		  'taker' => 0.0025,
                },
            },
    },
}

sub ticker {
  my $self = shift;
  my %vars = @_;

  $self->get(
    url => 'https://poloniex.com/public?command=returnTicker',
    on_result => sub { $self->process_ticker(@_) },
    on_error  => sub { $self->common_error(@_) },
  );
}

sub process_ticker {
  my $self = shift;
  my $tx = shift;

  my $res   	= $tx->result->json;
  my $status    = 0;
  my $stat_date = time;
  foreach my $c (keys %$res) {
    my $d = $res->{$c};
    my $status = 0;
    $self->store_ticker(
      source		=> $self->config->{id},
      currency		=> $c,
      status		=> $d->{is_frozen}//0,
      date_ts		=> $stat_date,
      base_currency 	=> $self->config->{base_currency},
      base_usd_rate	=> $self->usd_rates->{$self->config->{base_currency}}//1,
      highest_bid	=> $d->{highestBid},
      lowest_ask	=> $d->{lowestAsk},
      opening_price	=> undef, #$d->{opening_price},
      closing_price	=> undef, #$d->{closing_price}, 
      min_price		=> $d->{low24hr},
      max_price		=> $d->{high24hr},
      average_price	=> undef, #$d->{average_price},
      units_traded	=> undef, #$d->{units_traded},
      volume_1day	=> $d->{quoteVolume},
      volume_7day	=> undef, #$d->{volume_7day}, 
    );
  }

  return 1;
}

















2;


