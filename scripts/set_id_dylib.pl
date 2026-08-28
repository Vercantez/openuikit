#!/usr/bin/perl
# set_id_dylib.pl FILE NEWNAME
# Rewrite ONLY the LC_ID_DYLIB name of a 64-bit little-endian Mach-O, in place.
#
# WHY THIS EXISTS AT ALL, AND WHY IT IS NOT GOING AWAY WITH THE NEXT LLVM BUMP.
# llvm-install-name-tool cannot do this job on two of the libraries this repo
# has to rename, for two DIFFERENT reasons, and neither is a version skew:
#   * Apple's staged libswiftCore.dylib   -- LC_SEGMENT_SPLIT_INFO (cmd 0x1e)
#   * machorun's libc++.1.dylib (post-#55) -- LC_REEXPORT_DYLIB   (cmd 0x8000001f)
# Measured 2026-08-27: llvm-install-name-tool-18 (container) AND Homebrew LLVM
# 21.1.3 (host) BOTH fail on the libc++ case with the identical message
# `unsupported load command (cmd=0x8000001f)`. llvm-objcopy does not model the
# command; three LLVM major versions apart makes that a design fact, not a bug
# waiting to be fixed upstream, so "install a newer llvm" is not the fix.
# Apple's own install_name_tool handles both and is not available in the
# container (and reaching for it would put a macOS step inside a build that is
# otherwise reproducible under `--network none` on Linux).
#
# GRADED AGAINST APPLE'S TOOL, NOT AGAINST ITSELF. scripts/set_id_dylib_test.sh
# runs this and `xcrun install_name_tool -id` over the same input and requires
# the outputs to be BYTE-IDENTICAL, in both the fits-in-place case (libSystem.B,
# 32-byte name field, 30 bytes needed) and the must-grow case (libc++.1, 24-byte
# field, 27 needed -> cmdsize 48->56). A hand-rolled Mach-O writer that only
# agrees with itself is how you ship a plausible file.
#
# No python in the build image (perl only), hence perl.
use strict; use warnings;

my ($path, $newname) = @ARGV;
die "usage: set_id_dylib.pl FILE NEWNAME\n" unless defined $path && defined $newname;

my $LC_SEGMENT_64 = 0x19;
my $LC_ID_DYLIB   = 0x0D;

open my $fh, '+<:raw', $path or die "set_id_dylib: open $path: $!\n";
my $data = do { local $/; <$fh> };
my $orig_len = length $data;

my ($magic) = unpack('L', substr($data, 0, 4));
die sprintf("set_id_dylib: not a 64-bit LE Mach-O: magic %#x (fat files must be thinned first)\n", $magic)
    unless $magic == 0xFEEDFACF;
my ($ncmds, $sizeofcmds) = unpack('LL', substr($data, 16, 8));
my $HDR = 32;                                  # sizeof(mach_header_64)
my $end_of_lc = $HDR + $sizeofcmds;

# ---- pass 1: locate LC_ID_DYLIB and the first byte of non-header content ----
# Growing a load command is only safe inside the padding the linker leaves
# between the end of the load commands and the first section's file offset.
# That bound is the whole safety argument, so it is MEASURED here rather than
# assumed: every other file offset in the file (symtab, dyld info, exports
# trie) is absolute and unaffected by shifting the commands themselves.
my ($id_off, $id_cmdsize, $id_nameoff);
my $first_content;
my $off = $HDR;
for my $i (1 .. $ncmds) {
    die "set_id_dylib: load commands run past sizeofcmds at cmd $i\n" if $off + 8 > $end_of_lc;
    my ($cmd, $cmdsize) = unpack('LL', substr($data, $off, 8));
    die "set_id_dylib: zero cmdsize at cmd $i\n" if $cmdsize < 8;
    if ($cmd == $LC_ID_DYLIB) {
        die "set_id_dylib: more than one LC_ID_DYLIB\n" if defined $id_off;
        ($id_off, $id_cmdsize) = ($off, $cmdsize);
        ($id_nameoff) = unpack('L', substr($data, $off + 8, 4));
    }
    if ($cmd == $LC_SEGMENT_64) {
        my $nsects = unpack('L', substr($data, $off + 64, 4));
        my $so = $off + 72;                    # sizeof(segment_command_64)
        for (1 .. $nsects) {
            my $secoff = unpack('L', substr($data, $so + 48, 4));
            # A zerofill section (__bss) has fileoff 0 and owns no file bytes.
            $first_content = $secoff if $secoff && (!defined $first_content || $secoff < $first_content);
            $so += 80;                         # sizeof(section_64)
        }
    }
    $off += $cmdsize;
}
die "set_id_dylib: no LC_ID_DYLIB in $path\n" unless defined $id_off;
die "set_id_dylib: no section with file content in $path\n" unless defined $first_content;

# ---- how much room does the new name need? ---------------------------------
my $needed = $id_nameoff + length($newname) + 1;
$needed = ($needed + 7) & ~7;                  # load commands are 8-byte aligned
my $delta = $needed - $id_cmdsize;
$delta = 0 if $delta < 0;                      # shorter name: keep the command size, null-pad

if ($delta > 0) {
    my $slack = $first_content - $end_of_lc;
    die sprintf("set_id_dylib: cannot grow LC_ID_DYLIB by %d bytes -- only %d bytes of header padding\n"
              . "  (load commands end at %#x, first section content at %#x)\n"
              . "  A longer install name does not fit this file; choose a shorter one.\n",
                $delta, $slack, $end_of_lc, $first_content)
        if $slack < $delta;
    my $pad = substr($data, $end_of_lc, $delta);
    die sprintf("set_id_dylib: the %d bytes after the load commands are not zero (%s) -- refusing to overwrite them\n",
                $delta, unpack('H*', $pad))
        unless $pad eq "\0" x $delta;

    # Shift every load command after LC_ID_DYLIB up by $delta, then zero the
    # bytes the name field gains. The file does not change length: the growth
    # is taken out of the padding, exactly as Apple's install_name_tool does.
    my $tail_start = $id_off + $id_cmdsize;
    my $tail_len   = $end_of_lc - $tail_start;
    substr($data, $tail_start + $delta, $tail_len) = substr($data, $tail_start, $tail_len);
    substr($data, $tail_start, $delta) = "\0" x $delta;
    $id_cmdsize += $delta;
    $sizeofcmds += $delta;
    substr($data, $id_off + 4, 4) = pack('L', $id_cmdsize);
    substr($data, 20, 4)          = pack('L', $sizeofcmds);
}

my $start     = $id_off + $id_nameoff;
my $field_end = $id_off + $id_cmdsize;
die "set_id_dylib: internal: name does not fit after growth\n"
    if length($newname) > ($field_end - $start - 1);
substr($data, $start, $field_end - $start) = "\0" x ($field_end - $start);
substr($data, $start, length($newname))    = $newname;

die sprintf("set_id_dylib: internal: file length changed %d -> %d\n", $orig_len, length($data))
    unless length($data) == $orig_len;

seek($fh, 0, 0); print $fh $data; truncate($fh, length($data)); close $fh;
printf "LC_ID_DYLIB -> %s (cmdsize %d%s)\n", $newname, $id_cmdsize,
       $delta ? ", grown $delta from header padding" : "";
exit 0;
