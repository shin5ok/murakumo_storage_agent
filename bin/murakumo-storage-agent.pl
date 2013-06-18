#!/usr/bin/env perl
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

our $name = basename $0;

my $params = {
  admin_key  => $ENV{MURAKUMO_ADMIN_KEY},
  api_uri    => $ENV{MURAKUMO_API_URI},
  db_path    => $ENV{STORAGE_STATUS_DB_PATH},
  mount_path => $ENV{STORAGE_MOUNT_PATH},
  uuid       => $ENV{STORAGE_UUID},
};

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

