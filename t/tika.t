use strict;
use warnings;

use RT::Test tests => undef;

use lib './lib';

use RT::Extension::Tika;

sub read_file {
    local $/ = undef;
    open FP, "< $_[0]";
    my $data = <FP>;
    close FP;
    return $data;
}

my %files;
%files = map { $_ => read_file($_) } qw(
    t/docs/testOpenOffice2.odf
    t/docs/testOpenOffice2.odt
    t/docs/testPDF.pdf
    t/docs/testWORD.doc
    t/docs/testWORD.docx
);
    

is RT::Extension::Tika::mime_file($files{'t/docs/testOpenOffice2.odf'}), 'application/zip', 'test odf mime loading';
is RT::Extension::Tika::mime_file($files{'t/docs/testOpenOffice2.odt'}), 'application/vnd.oasis.opendocument.text', 'test odt mime loading';
is RT::Extension::Tika::mime_file($files{'t/docs/testPDF.pdf'}), 'application/pdf', 'test pdf mime loading';
is RT::Extension::Tika::mime_file($files{'t/docs/testWORD.doc'}), 'application/msword', 'test doc mime loading';
is RT::Extension::Tika::mime_file($files{'t/docs/testWORD.docx'}), 'application/zip', 'test docx mime loading';


is RT::Extension::Tika::config_url, 'http://localhost:9998/', 'check default config url';

my $request = RT::Extension::Tika::request( 
    RT::Extension::Tika::config_url,
    $files{'t/docs/testOpenOffice2.odf'},
    'application/zip');
is $request->is_error, '', 'not an error';
is $request->code, 200, 'request works';
like $request->content, qr/The quick brown fox jumps over the lazy dog/, 'odf content';    

like RT::Extension::Tika::extract($files{'t/docs/testOpenOffice2.odt'}), qr/This is a sample Open Office document/, 'odt extraction';
like RT::Extension::Tika::extract($files{'t/docs/testPDF.pdf'}), qr/Tika - Content Analysis Toolkit/, 'pdf extraction';
like RT::Extension::Tika::extract($files{'t/docs/testWORD.doc'}), qr/This is a sample Microsoft Word Document/, 'doc extraction';
like RT::Extension::Tika::extract($files{'t/docs/testWORD.docx'}), qr/This is a sample Microsoft Word Document/, 'docx extraction';
        

done_testing;
