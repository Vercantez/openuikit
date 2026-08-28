#!/usr/bin/perl
# macho_same_except_id.pl A B
# Answer ONE question about two 64-bit Mach-Os: are they the same library apart
# from their LC_ID_DYLIB install name?
#
# WHY THE QUESTION IS NOT `cmp`. A guest root's libSystem.real.dylib IS
# machorun's libSystem.B.dylib -- the same build, the same __text, the same
# exports -- carrying a different install name so an umbrella can re-export it
# (full/scripts/build_full.sh). `cmp` therefore reports DRIFT on a file that has
# not drifted, and that false alarm is not harmless: its remedy overwrote the
# derived layer of scratch/mrroot_full and left it unable to load a single guest
# for most of 2026-08-27.
#
# WHY NOT "same export set + same __text" EITHER. That was the first proposal
# and it is WEAKER than what is available here: it says nothing about
# __DATA_CONST, the fixups, the exports trie, or the other load commands, and it
# needs nm/otool, which are different programs on the two hosts this runs on.
# The rewrite set_id_dylib.pl performs is bounded, so the check can be exact:
# strip the LC_ID_DYLIB command from both, ignore the header's sizeofcmds field
# and the zero padding after the load commands (both legitimately change when
# the command grows), and require EVERYTHING ELSE to be byte-identical --
# every other load command in order, and every byte from the first section's
# file offset to the end of file.
#
# Prints a canonical digest for each side so a caller can show two numbers that
# have to agree, and the two install names. Exit 0 = same library, 1 = not,
# 2 = could not tell (not a Mach-O, no LC_ID_DYLIB).
use strict; use warnings;
use Digest::SHA qw(sha256_hex);

my ($pa, $pb) = @ARGV;
die "usage: macho_same_except_id.pl A B\n" unless defined $pa && defined $pb;

sub canon {
    my ($path) = @_;
    open my $f, '<:raw', $path or return { err => "open $path: $!" };
    my $d = do { local $/; <$f> };
    close $f;
    return { err => sprintf("%s: not a 64-bit LE Mach-O (magic %#x)", $path, unpack('L', substr($d,0,4))) }
        unless length($d) >= 32 && unpack('L', substr($d, 0, 4)) == 0xFEEDFACF;
    my ($ncmds, $soc) = unpack('LL', substr($d, 16, 8));
    my ($off, $lc, $id, $first) = (32, '', undef, undef);
    for my $i (1 .. $ncmds) {
        return { err => "$path: load commands overrun" } if $off + 8 > 32 + $soc;
        my ($cmd, $cs) = unpack('LL', substr($d, $off, 8));
        return { err => "$path: bad cmdsize at command $i" } if $cs < 8;
        if ($cmd == 0x0D) {                       # LC_ID_DYLIB -- the one thing allowed to differ
            my $no = unpack('L', substr($d, $off + 8, 4));
            $id = (split /\0/, substr($d, $off + $no, $cs - $no))[0];
        } else {
            $lc .= substr($d, $off, $cs);
        }
        if ($cmd == 0x19) {                       # LC_SEGMENT_64
            my $ns = unpack('L', substr($d, $off + 64, 4)); my $so = $off + 72;
            for (1 .. $ns) {
                my $o = unpack('L', substr($d, $so + 48, 4));
                $first = $o if $o && (!defined $first || $o < $first);
                $so += 80;
            }
        }
        $off += $cs;
    }
    return { err => "$path: no LC_ID_DYLIB" }        unless defined $id;
    return { err => "$path: no section with content" } unless defined $first;
    # Header with sizeofcmds blanked; every non-ID load command in order; the
    # whole file from the first section onward. The bytes deliberately NOT
    # covered are exactly the two that a legal rename moves: sizeofcmds, and the
    # zero padding between the load commands and the first section.
    my $h = substr($d, 0, 32); substr($h, 20, 4) = "\0\0\0\0";
    return { id => $id, len => length($d), first => $first,
             digest => substr(sha256_hex($h . $lc . substr($d, $first)), 0, 12) };
}

my $a = canon($pa);
my $b = canon($pb);
for ($a, $b) { if ($_->{err}) { print "UNGRADABLE $_->{err}\n"; exit 2 } }

if ($a->{digest} eq $b->{digest} && $a->{len} == $b->{len}) {
    printf "SAME %s  id(A)=%s id(B)=%s  (identical outside LC_ID_DYLIB; %d bytes)\n",
        $a->{digest}, $a->{id}, $b->{id}, $a->{len};
    exit 0;
}
printf "DIFFER A=%s B=%s  id(A)=%s id(B)=%s%s\n",
    $a->{digest}, $b->{digest}, $a->{id}, $b->{id},
    ($a->{len} != $b->{len} ? sprintf("  sizes %d vs %d", $a->{len}, $b->{len}) : "");
exit 1;
