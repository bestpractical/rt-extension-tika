use inc::Module::Install;

RTx     'RT-Extension-Tika';
license 'gplv2';
repository 'https://github.com/bestpractical/rt-extension-tika';

requires_rt '4.4.0';
rt_too_new '4.6.0';
install_share 'jar';

my ($lib_path) = $INC{'RT.pm'} =~ /^(.*)[\\\/]/;
my $local_lib_path = "$RT::LocalPath/lib";
unshift @INC, $local_lib_path, $lib_path;

use Config;
my $secure_perl_path = $Config{perlpath};
if ($^O ne 'VMS') {
    $secure_perl_path .= $Config{_exe}
        unless $secure_perl_path =~ m/$Config{_exe}$/i;
}

my @tools;
use File::Find ();
File::Find::find({
	no_chdir => 1,
	wanted => sub {
		if ( -f $File::Find::name ) {
			$File::Find::name =~ /([^\.]+)\.in$/;
			push @tools, $1;
		}
	},
	},
	'sbin'
);

use Data::Dumper;
print STDERR Dumper  \@tools;

substitute(
	{ 
		PERL => $ENV{PERL} || $secure_perl_path,
		RT_LIB_PATH => join(' ',$local_lib_path,$lib_path ) 
	}, {
		sufix => '.in'
	},
	@tools
) if @tools; 

requires 'Apache::Tika';
requires 'File::MimeInfo::Magic';
requires 'IO::Scalar';

sign;
WriteAll;
