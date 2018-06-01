package Exchange::Bithumb;
use strict;
use warnings;

use parent 'Exchange';

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;
  $self->{config} = {
	    'id' => 'bithumb',
            'name' => 'Bithumb',
            'countries' => 'KR', 
            'rateLimit' => 500,
            'base_currency' => 'KRW',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
            'urls' => {
                'logo' => 'https://user-images.githubusercontent.com/1294454/30597177-ea800172-9d5e-11e7-804c-b9d4fa9b56b0.jpg',
                'api' => {
                    'public' => 'https://api.bithumb.com/public',
                    'private' => 'https://api.bithumb.com',
                },
                'www' => 'https://www.bithumb.com',
                'doc' => 'https://www.bithumb.com/u1/US127',
            },
            'can' => {
            	'rest'  => 1,
            	'push'  => undef,
            	'wsock' => undef,
            },
            'fees' => {
                'trading' => {
                    'maker' => 0.15 / 100,
                    'taker' => 0.15 / 100,
                },
            },
    },
}

sub ticker {
  my $self = shift;
  my %vars = @_;

  $self->get(
    url => 'https://api.bithumb.com/public/ticker/ALL',
    on_result => sub { $self->process_ticker(@_) },
    on_error  => sub { $self->common_error(@_) },
  );
}

sub process_ticker {
  my $self = shift;
  my $tx = shift;

  my $res   	= $tx->result->json;
  my $status    = delete $res->{status};
  my $stat_date = delete $res->{data}->{date};
  my $currencies = delete $res->{data};
  foreach my $c (keys %$currencies) {
    my $d = $currencies->{$c};
    $self->store_ticker(
      source		=> $self->config->{id},
      currency		=> $c,
      status		=> $status,
      date_ts		=> $stat_date/1000,
      base_currency 	=> $self->config->{base_currency},
      base_usd_rate	=> $self->usd_rates->{$self->config->{base_currency}}//1,
      highest_bid	=> $d->{buy_price},
      lowest_ask	=> $d->{sell_price},
      opening_price	=> $d->{opening_price},
      closing_price	=> $d->{closing_price}, 
      min_price		=> $d->{min_price},
      max_price		=> $d->{max_price},
      average_price	=> $d->{average_price},
      units_traded	=> $d->{units_traded},
      volume_1day	=> $d->{volume_1day},
      volume_7day	=> $d->{volume_7day}, 
    );
  }

  return 1;
}










2;


