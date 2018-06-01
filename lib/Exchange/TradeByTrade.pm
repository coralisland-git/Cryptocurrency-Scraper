package Exchange::TradeByTrade;
use strict;
use warnings;

use parent 'Exchange';

use Data::Dumper;
use Try::Tiny;

sub _init {
  my $self = shift;
  $self->{config} = {
	    'id' => 'tradebytrade',
            'name' => 'TradeByTrade',
            'countries' => 'BZ', 
            'rateLimit' => 500, # no info
            'base_currency' => 'BZD',
            'has' => {
                'CORS' => 1,
                'fetchTickers' => 1,
                'withdraw' => 1,
            },
            'urls' => {
                'logo' => 'https://tradebytrade.com/wp-content/uploads/2017/10/logo-header.png',
                'api' => 'https://tradebytrade.com/wp-admin/admin-ajax.php',
                'www' => 'https://tradebytrade.com/',
                'doc' => '',
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
 
  $self->post(
    url => 'https://tradebytrade.com/wp-admin/admin-ajax.php',
    vars => {"action" => "my_action"},
    on_result => sub { $self->process_ticker(@_) },
    on_error  => sub { $self->common_error(@_) },
  );
}

sub process_ticker {
  my $self = shift;
  my $tx = shift;

  my $currencies    = $tx->result->json;

  foreach my $c (keys %$currencies) {
    my $currency = $currencies->{$c};

    $self->store_ticker(
      source    => $self->config->{id},
      currency    => $c,
      status    => 0, # proper status for the ticker w/o errors
      date_ts   => time,
      base_currency   => $self->config->{base_currency},
      base_usd_rate => $self->usd_rates->{$self->config->{base_currency}}//1,
      highest_bid => $currency->{price},
      lowest_ask  => $currency->{price},
      opening_price => 0,
      closing_price => 0, 
      min_price   => $currency->{low},
      max_price   => $currency->{high},
      average_price => 0,
      units_traded  => 0,
      volume_1day => $currency->{volume},
      volume_7day => 0, 
    );
    
  }

  return 1;
}

2;



