package Exchange::Kraken;
use strict;
use warnings;

use parent 'Exchange';

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;
  $self->{config} = {
	    'id' => 'kraken',
            'name' => 'Kraken',
            'countries' => 'US', 
            'rateLimit' => 3000,
            'base_currency' => 'USD',
            'has' => {
                'createDepositAddress' => 1,
                'fetchDepositAddress' => 1,
                'CORS' => undef,
                'fetchCurrencies' => 1,
                'fetchTickers' => 1,
                'fetchOHLCV' => 1,
                'fetchOrder' => 1,
                'fetchOpenOrders' => 1,
                'fetchClosedOrders' => 1,
                'fetchMyTrades' => 1,
		'withdraw' => 1,
            },
            'urls' => {
                'logo' => 'https://user-images.githubusercontent.com/1294454/27766599-22709304-5ede-11e7-9de1-9f33732e1509.jpg',
                'api' =>  'https://api.kraken.com',
                'www' => 'https://www.kraken.com',
                'doc' =>  [
                    'https://www.kraken.com/en-us/help/api',
                    'https://github.com/nothingisdead/npm-kraken-api',
                ],
                'fees' => [
                    'https://www.kraken.com/en-us/help/fees',
                    'https://support.kraken.com/hc/en-us/articles/201396777-What-are-the-deposit-fees-',
                    'https://support.kraken.com/hc/en-us/articles/201893608-What-are-the-withdrawal-fees-',
		],
            },
            'can' => {
            	'rest'  => 1,
            	'push'  => undef,
            	'wsock' => undef,
            },
            'fees' => {
                'trading' => {
		    'taker' => 0.26 / 100,
		    'maker' => 0.16 / 100,
                },
            },
    },
}

sub ticker {
  my $self = shift;
  my %vars = @_;

  $self->get(
    url => 'https://api.kraken.com/0/public/Ticker?pair=XXRPZUSD,DASHUSD,LTCUSD,XBTUSD,ETHUSD,EOSETH,EOSXBT',
    on_result => sub { $self->process_ticker(@_) },
    on_error  => sub { $self->common_error(@_) },
  );
}

sub process_ticker {
  my $self = shift;
  my $tx = shift;

  my $res   	= $tx->result->json;
  my $errors    = delete $res->{errors};
  my $stat_date = time;
  my $currencies = delete $res->{result};
  foreach my $c (keys %$currencies) {
    my $d = $currencies->{$c};
    my $status = 0;
    $self->store_ticker(
      source		=> $self->config->{id},
      currency		=> $c,
      status		=> $status,
      date_ts		=> $stat_date,
      base_currency 	=> $self->config->{base_currency},
      base_usd_rate	=> $self->usd_rates->{$self->config->{base_currency}}//1,
      highest_bid	=> $d->{b}->[0],
      lowest_ask	=> $d->{a}->[0],
      opening_price	=> $d->{o},
      closing_price	=> $d->{c}->[0], 
      min_price		=> $d->{l}->[1],
      max_price		=> $d->{h}->[1],
      average_price	=> $d->{p}->[1],
      units_traded	=> $d->{t}->[1],
      volume_1day	=> $d->{v}->[1],
      volume_7day	=> undef, 
    );
  }

  return 1;
}













2;


