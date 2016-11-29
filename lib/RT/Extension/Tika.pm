use strict;
use warnings;
package RT::Extension::Tika;

use Apache::Tika;
use File::MimeInfo::Magic qw/ mimetype /;
use IO::Scalar;

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

=head1 RT VERSION

Works with RT 4.4.1.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::Tika');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::Tika));

or add C<rt::extension::tika> to your existing C<@Plugins> line.

By default this extension will index text, html, pdf, doc, and docx files.
You can add additional mime types by adding them to a list:

    Set(@TikaMimeTypes,'application/rtf','application/x-rtf',
         'application/vnd.oasis.opendocument.text',
         'application/vnd.oasis.opendocument.text-master');

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

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

sub extractFile {
	my ($filename) = @_;
	open my $fh, "< $filename";
	my $file = do { local $/;  <$fh> };
	close $fh;
	return extract($file);
}

sub extract {
	my ($file) = @_;
	my $tika = Apache::Tika->new();

	my $io = new IO::Scalar \$file;
        my $mime_type = mimetype($io);

	return $tika->tika($file,$mime_type);
}

1;
