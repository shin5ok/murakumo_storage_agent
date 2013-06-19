#!/usr/bin/env perl
# chkconfig: 35 99 10
# description: murakumo storage agent
use 5.014;
use warnings;
use strict;
use App::Daemon qw( daemonize );
use JSON;
use FindBin;
use File::Basename;
use opts;

use lib qq{$FindBin::Bin/../lib};
use Murakumo::Storage_Agent;

our $name        = basename $0;
our $config_path = qq{/root/$name.json};

my $config;
if ( -f $config_path ) {
  open my $fh, "<", $config_path;
  my $json = do { local $/; <$fh> };
  eval {
    $config  = decode_json $json;
  };
  close $fh;
}

my $params = {
  admin_key  => $ENV{MURAKUMO_ADMIN_KEY},
  api_uri    => $ENV{MURAKUMO_API_URI},
  db_path    => $ENV{STORAGE_STATUS_DB_PATH},
  mount_path => $ENV{STORAGE_MOUNT_PATH},
  uuid       => $ENV{STORAGE_UUID},
};

if (defined $config and ref $config eq 'HASH') {
  %$params = (%$params, %$config);
}

my $sa = Murakumo::Storage_Agent->new( $params );

local $App::Daemon::logfile    = "/dev/null";
local $App::Daemon::pidfile    = "/var/run/$name.pid";
local $App::Daemon::background = 1;
local $App::Daemon::kill_sig   = 15;
local $App::Daemon::as_user    = "root";

daemonize;

while (1) {
  $sa->run;
  sleep 10;
}

