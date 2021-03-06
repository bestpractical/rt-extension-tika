use strict;
use warnings;
package RT::Extension::Tika;

use File::MimeInfo::Magic qw/ mimetype /;
use IO::Scalar;
use LWP::UserAgent;

our $VERSION = '0.01';

=head1 NAME

rt-extension-tika - adds Apache Tika document conversion for full text search

=head1 DESCRIPTION

RT has the option of providing full text search through the features of the 
underlying database, but it can only search attachments that are in plain
text and html.  If your organization uses typical office software, it will
often be handy to add documents to a ticket in various office document formats.
This module makes those document attachments searchable through the same
full text search as the rest of your tickets.

Apache Tika is a project that extracts plain text from various document formats
for use in search engines.  This plugin requires running a tika-server process
either on the same machine as RT or on another machine, to provide the text 
extraction for the different supported document types.

Currently this module only supports MySQL and PostgreSQL databases for indexing.


=head1 RT VERSION

Works with RT 4.4.1.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Configure Full text indexing

In order to use this extension, you will first need to configure
your RT to use fulltext indexing by running the script:
    
    /opt/rt4/sbin/rt-setup-fulltext-index

This will create a new table in your database and prompt you to
configure your F</opt/rt4/etc/RT_SiteConfig.pm> for your particular
database configuration, such as: 

    Set( %FullTextSearch,
        Enable     => 1,
        Indexed    => 1,
        Table      => 'AttachmentsIndex'
    );


=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::Tika');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::Tika));

or add C<rt::extension::tika> to your existing C<@Plugins> line.

To select the attachment types to index, set the C<@TikaMimeTypes>
value to a list of mime types for indexing:

    Set(@TikaMimeTypes,
            'text/plain',
            'text/html',
            'application/zip',
            'application/pdf',
            'application/vnd.oasis.opendocument.text',
            'application/vnd.oasis.opendocument.text-master',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'application/msword',
            'application/vnd.ms-excel',
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'application/rtf',
            'application/x-rtf'
    );

The above list contains plain text, html, pdfs, OpenOffice, Microsoft Word and Excel files.

If you want to run the Tika server on a different host from your RT instance you can 
configure the C<$TikaURL> value to point it at that host:

    Set($TikaURL, 'http://someotherhost:9998/');


=item Start the tika server

From  the /opt/rt4 directory you can start the server using:

    ./local/plugins/RT-Extension-Tika/sbin/start-tika-server

Optionally you can run it via java as:

    java -jar /opt/rt4/local/plugins/RT-Extension-Tika/lib/auto/share/dist/RT-Extension-Tika/tika-server.jar

You can get a list of options (host, port, CORS) by running:

    java -jar /opt/rt4/local/plugins/RT-Extension-Tika/lib/auto/share/dist/RT-Extension-Tika/tika-server.jar -?

By default the server will listen on localhost:9998

=item Add the indexer to a cron job

In the directory /opt/rt4 you can run the indexer as:

	./local/plugins/RT-Extension-Tika/sbin/rt-tika-fulltext-indexer

This indexer replaces the rt-fulltext-indexer.  If you are
currently running that make sure that job first.

=back

=head1 TESTING

In order to run the unit tests for this extension, you should:

    java -jar jar/tika-server.jar &
    prove -I/opt/rt4/lib t/tika.t

These tests require that the server be running locally on the
default port in order to work.  The sample test files are in
the t/docs/ directory, and are loaded relative to the current
working directory.

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-rt-extension-tika@rt.cpan.org|mailto:bug-rt-extension-tika@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=rt-extension-tika>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2016 by Dave Goehrig

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut


sub config_url {
    RT->Config->Get('TikaUrl') || 'http://localhost:9998/';
}

sub mime_file {
    my ($file) = @_;
	my $io = new IO::Scalar \$file;
    mimetype($io);
}

sub request {
    my($url,$file,$mimetype) = @_;
    my $ua = LWP::UserAgent->new();
    $ua->put($url . "/tika", 
        'Accept' => 'text/plain',
        'Content-Type' => $mimetype,
        'Content' => $file
    );
}

sub extract {
	my ($file) = @_;
	my $url = config_url;
    my $mime_type = mime_file($file);
    my $response = request($url,$file,$mime_type);
    print STDERR "$mime_type\n";
    if ($response->is_error) {
        return ('', $response->message || 'error'); 
    } 
    return ($response->content);
}

1;
