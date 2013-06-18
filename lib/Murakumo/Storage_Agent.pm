package Murakumo::Storage_Agent;

use 5.014;
use strict;
use warnings FATAL => 'all';
use Class::Accessor::Lite ( rw => [qw( ua uuid admin_key api_uri db_path mount_path )] );
use URI;
use Data::Dumper;
use JSON;
use DBI;
use LWP::UserAgent;
use Sys::Syslog qw(:DEFAULT);
use IPC::Cmd;

local $SIG{INT}  = local $SIG{TERM} = sub { warn "stopped..." };

=head1 NAME

Murakumo::Storage_Agent - The great new Murakumo::Storage_Agent!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

our $SYSLOG_FACILITY = q{local0};
our @UA_SSL_OPTS     = ( verify_hostname => 0, SSL_verify_mode => q{SSL_VERIFY_NONE} );
our $UA_TIMEOUT      = 30;

our $storage_regist_path = q{/admin/storage_register_status};


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Murakumo::Storage_Agent;

    my $foo = Murakumo::Storage_Agent->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub new {
  my ($class, $params) = @_;
  my $obj = bless $params, $class;

  my $ua = LWP::UserAgent->new;
  $ua->timeout ( $UA_TIMEOUT  );
  $ua->ssl_opts( @UA_SSL_OPTS );

  $obj->ua( $ua );

  return $obj;
}

sub json_post {
   my $self = shift;
   my ($uri, $params) = @_;

   my $request = HTTP::Request->new( 'POST', $uri );
   $request->header('Content-Type' => 'application/json');
   $request->content( encode_json $params );

   my $response = $self->ua->request( $request );

   return $response;

}

=head2 function2

=cut

sub run {
  my ($self) = @_;

  my $uri = URI->new( $self->api_uri . $storage_regist_path . "/" . $self->uuid );
  $uri->query_form( admin_key => $self->admin_key );

  local $@;
  eval {
    my $params = $self->gathering_params;

    my $r = $self->json_post( $uri, $params );

    if (! $r->is_success) {
      logging ( "*** json post http error" );
    }
    my $content = $r->content;
    if (my $v = decode_json $content) {
      if (! $v->{result}) {
        logging ( "*** api result failure" );
      }
    }
  };

  logging ( $@ ) if $@;

}

sub logging {
  my $string = shift;

  {
    no strict 'refs';
    warn $string if $ENV{DEBUG};
  }

  openlog __PACKAGE__, "ndelay", $SYSLOG_FACILITY;
  syslog ( "info",  $string );
  closelog;

}

sub gathering_params {
  my $self = shift;
  my ($iowait, $avail_size);

  my $result = {};

  {
    # cpu  1139530 3529613 1820519 6796945469 12447146 62005 187934 0 0
    my $cpu;
    open my $fh, "<", "/proc/stat";
    ($cpu) = grep { /^cpu\s/ } <$fh>;
    close $fh;
    my @cpu_stats = $cpu =~ /(\d+)/g;
    $result->{iowait} = $cpu_stats[4];
  }

  {
    my @results = IPC::Cmd::run( command => "/bin/df", timeout => 10 );
    # /dev/sdb1            960809912 123678940 788324596  14% /export/vps
    for my $line ( split /\n/, $results[3]->[0] ) {
      if ($line =~ /(\d+) \s+ \S+ \s+ (\S+) \s* $/x) {
        if ($2 eq $self->mount_path) {
          $result->{avail_size} = $1;
        }
      }
    }
  }

  warn Dumper $result;

  return $result;

}

=head1 AUTHOR

shin5ok, C<< <shin5ok at 55mp.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-murakumo_storage_agent at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=murakumo_storage_agent>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Murakumo::Storage_Agent


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=murakumo_storage_agent>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/murakumo_storage_agent>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/murakumo_storage_agent>

=item * Search CPAN

L<http://search.cpan.org/dist/murakumo_storage_agent/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 shin5ok.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Murakumo::Storage_Agent
