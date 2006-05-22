use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::BF2S',
    VERSION_FROM      => 'lib/Net/BF2S.pm', # finds $VERSION
    PREREQ_PM         => {'WWW::BF2S' => "0"},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/BF2S.pm', # retrieve abstract from module
       AUTHOR         => 'Dusty Wilson <bf2s-module@dusty.hey.nu>') : ()),
);
