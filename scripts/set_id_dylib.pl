#!/usr/bin/perl
# set_id_dylib.pl FILE NEWNAME
# Rewrite only the LC_ID_DYLIB name of a 64-bit little-endian Mach-O, in place,
# requiring the new name to fit the existing command (null-padded). Gives the
# staged libswiftCore.dylib a distinct identity so an umbrella can reexport it
# (llvm-install-name-tool can't touch it -- chained fixups). No python in the
# build image, hence perl.
use strict; use warnings;
my ($path, $newname) = @ARGV;
open my $fh, '+<:raw', $path or die "open $path: $!";
my $data = do { local $/; <$fh> };
my ($magic) = unpack('L', substr($data, 0, 4));
die sprintf("not 64-bit LE Mach-O: %#x\n", $magic) unless $magic == 0xFEEDFACF;
my ($ncmds) = unpack('L', substr($data, 16, 4));
my $off = 32;                       # sizeof(mach_header_64)
my $LC_ID_DYLIB = 0xD;
for (1 .. $ncmds) {
    my ($cmd, $cmdsize) = unpack('LL', substr($data, $off, 8));
    if ($cmd == $LC_ID_DYLIB) {
        my ($name_off) = unpack('L', substr($data, $off + 8, 4));
        my $start = $off + $name_off;
        my $field_end = $off + $cmdsize;
        my $nb = $newname;
        die "new name too long for field\n" if length($nb) > ($field_end - $start - 1);
        substr($data, $start, $field_end - $start) = "\0" x ($field_end - $start);
        substr($data, $start, length($nb)) = $nb;
        seek($fh, 0, 0); print $fh $data; truncate($fh, length($data)); close $fh;
        print "LC_ID_DYLIB -> $newname\n"; exit 0;
    }
    $off += $cmdsize;
}
die "no LC_ID_DYLIB found\n";
