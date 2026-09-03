#!/usr/bin/env perl
# Deterministic, fail-closed attestations for the reusable SwiftUI guest proof.
# This is deliberately limited to core Perl modules available in the pinned
# swift-macho-spike:noble image.

use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use File::Basename qw(dirname basename);
use Getopt::Long qw(GetOptionsFromArray);

sub fail { die "focus_widget_guest_attest: $_[0]\n"; }

sub file_sha256 {
    my ($path) = @_;
    open my $fh, '<:raw', $path or fail("cannot read $path: $!");
    my $sha = Digest::SHA->new(256);
    $sha->addfile($fh);
    close $fh or fail("cannot close $path: $!");
    return $sha->hexdigest;
}

sub scalar_sha256 { return sha256_hex(defined $_[0] ? $_[0] : ''); }

sub clean_field {
    my ($value, $what) = @_;
    fail("$what contains a tab or newline") if $value =~ /[\t\r\n]/;
    return $value;
}

sub node_record {
    my ($physical, $logical) = @_;
    clean_field($logical, 'inventory path');
    my @st = lstat($physical);
    fail("missing inventory node $physical") unless @st;
    if (-l _) {
        my $target = readlink($physical);
        fail("cannot read symlink $physical: $!") unless defined $target;
        clean_field($target, 'symlink target');
        return join("\t", 'node', 'symlink', scalar_sha256($target), $logical);
    }
    return join("\t", 'node', 'directory', '-', $logical) if -d _;
    return join("\t", 'node', 'file', file_sha256($physical), $logical) if -f _;
    fail("unsupported inventory node type at $physical");
}

sub inventory_tree {
    my ($physical, $logical, $records) = @_;
    push @$records, node_record($physical, $logical);
    return if -l $physical || -f $physical;
    fail("inventory tree root is not a directory: $physical") unless -d $physical;
    opendir my $dh, $physical or fail("cannot enumerate $physical: $!");
    my @names = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh or fail("cannot close directory $physical: $!");
    for my $name (@names) {
        clean_field($name, 'inventory basename');
        inventory_tree("$physical/$name", "$logical/$name", $records);
    }
}

sub inventory_command {
    my (@args) = @_;
    my ($w, $uikit, $full, $sysroot, $opencombine_root, $opencombine_artifacts);
    GetOptionsFromArray(
        \@args,
        'w=s'       => \$w,
        'uikit=s'   => \$uikit,
        'full=s'    => \$full,
        'sysroot=s' => \$sysroot,
        'opencombine-root=s' => \$opencombine_root,
        'opencombine-artifacts=s' => \$opencombine_artifacts,
    ) or fail('invalid inventory options');
    fail('inventory takes no positional arguments') if @args;
    fail('inventory requires --w, --uikit, --full, --sysroot, and --opencombine-root')
        unless defined($w) && defined($uikit) && defined($full) && defined($sysroot)
            && defined($opencombine_root);

    fail('OpenCombine root must be an absolute canonical path')
        unless $opencombine_root =~ m{^/}
            && normalize_absolute($opencombine_root) eq $opencombine_root;
    fail("OpenCombine root is outside project root $w: $opencombine_root")
        unless beneath($opencombine_root, $w);

    $opencombine_artifacts //= "$opencombine_root/export/artifacts";
    fail('OpenCombine artifacts must be an absolute canonical path')
        unless $opencombine_artifacts =~ m{^/}
            && normalize_absolute($opencombine_artifacts) eq $opencombine_artifacts;
    fail("OpenCombine artifacts are outside project root $w: $opencombine_artifacts")
        unless beneath($opencombine_artifacts, $w);

    my @records;
    my $oc_art_logical = ($opencombine_artifacts =~ m{/export-x86_64/artifacts$})
        ? 'opencombine/export-x86_64/artifacts'
        : 'opencombine/export/artifacts';
    my @opencombine_files = (
        [ "$opencombine_root/export/RESULT.txt", 'opencombine/export/RESULT.txt' ],
        [ "$opencombine_artifacts/OpenCombine.o", "$oc_art_logical/OpenCombine.o" ],
        [ "$opencombine_artifacts/OpenCombine.swiftmodule", "$oc_art_logical/OpenCombine.swiftmodule" ],
        [ "$opencombine_artifacts/OpenCombine.swiftdoc", "$oc_art_logical/OpenCombine.swiftdoc" ],
        [ "$opencombine_root/source/Sources/COpenCombineHelpers/COpenCombineHelpers.cpp", 'opencombine/source/Sources/COpenCombineHelpers/COpenCombineHelpers.cpp' ],
        [ "$opencombine_root/source/Sources/COpenCombineHelpers/include/COpenCombineHelpers.h", 'opencombine/source/Sources/COpenCombineHelpers/include/COpenCombineHelpers.h' ],
        [ "$opencombine_root/source/Sources/COpenCombineHelpers/include/module.modulemap", 'opencombine/source/Sources/COpenCombineHelpers/include/module.modulemap' ],
    );
    require_regular_beneath_no_links($_->[0], $w, "OpenCombine input $_->[1]")
        for @opencombine_files;
    my @files = (
        [ "$w/full/swiftui/build_focus_widget_guest.sh", 'project/full/swiftui/build_focus_widget_guest.sh' ],
        [ "$w/full/swiftui/focus_widget_guest_attest.pl", 'project/full/swiftui/focus_widget_guest_attest.pl' ],
        [ "$w/full/swiftui/FocusWidgetBundle.generated.swift", 'project/full/swiftui/FocusWidgetBundle.generated.swift' ],
        [ "$w/full/swiftui/FocusWidgetGuestMain.swift", 'project/full/swiftui/FocusWidgetGuestMain.swift' ],
        [ "$w/full/scripts/build_full.sh", 'project/full/scripts/build_full.sh' ],
        [ "$w/full/oracle-opencombine/Combine.swift", 'project/full/oracle-opencombine/Combine.swift' ],
        [ "$w/full/oracle-opencombine/patches/COpenCombineHelpers-pthread-recursive.patch", 'project/full/oracle-opencombine/patches/COpenCombineHelpers-pthread-recursive.patch' ],
        [ "$w/full/scripts/uihelpers_subject.sh", 'project/full/scripts/uihelpers_subject.sh' ],
        [ "$w/scripts/require_fresh_root.sh", 'project/scripts/require_fresh_root.sh' ],
        [ "$w/scripts/macho_same_except_id.pl", 'project/scripts/macho_same_except_id.pl' ],
        [ "$w/full/foundation/foundationessentials_import_guard.swift", 'project/full/foundation/foundationessentials_import_guard.swift' ],
        [ "$full/uihelpers-subject.sha256", 'build-full/uihelpers-subject.sha256' ],
        map({ [ "$full/$_", "build-full/$_" ] }
            qw(openuikit.o opencoregraphics.o cportableio.o cstbtruetype.o
               hostclock.o swiftcorepatch.o)),
        map({ [ "$full/OpenUIKit.$_", "build-full/OpenUIKit.$_" ] }
            qw(swiftmodule swiftdoc swiftsourceinfo abi.json)),
        map({ [ "$full/OpenCoreGraphics.$_", "build-full/OpenCoreGraphics.$_" ] }
            qw(swiftmodule swiftdoc swiftsourceinfo abi.json)),
        @opencombine_files,
    );
    push @records, node_record($_->[0], $_->[1]) for @files;

    my @trees = (
        [ "$full/inc/CPortableIO", 'build-full/inc/CPortableIO' ],
        [ "$full/inc/CSTBTrueType", 'build-full/inc/CSTBTrueType' ],
        [ "$w/full/hostclock/include", 'project/full/hostclock/include' ],
        [ "$uikit/Sources/CQuartz/include", 'openuikit/Sources/CQuartz/include' ],
        [ "$uikit/Sources/Symbols", 'openuikit/Sources/Symbols' ],
        [ "$uikit/Sources/SwiftUI", 'openuikit/Sources/SwiftUI' ],
        [ "$w/scratch/swift-foundation/Sources/_FoundationCShims/include", 'upstream/swift-foundation/_FoundationCShims/include' ],
        [ "$full/foundation/essentials", 'build-full/foundation/essentials' ],
        [ "$full/foundation/collections", 'build-full/foundation/collections' ],
        [ "$full/foundation/os", 'build-full/foundation/os' ],
        [ "$full/foundation/cshims", 'build-full/foundation/cshims' ],
        [ $sysroot, 'sdk/sysroot_fe4' ],
    );
    inventory_tree($_->[0], $_->[1], \@records) for @trees;

    my @required_tbd = (
        [ "$sysroot/usr/lib/swift/libswiftCore.tbd", 'sdk/sysroot_fe4/usr/lib/swift/libswiftCore.tbd' ],
        [ "$sysroot/usr/lib/libSystem.tbd", 'sdk/sysroot_fe4/usr/lib/libSystem.tbd' ],
        [ "$sysroot/usr/lib/libobjc.tbd", 'sdk/sysroot_fe4/usr/lib/libobjc.tbd' ],
        [ "$sysroot/usr/lib/swift/libswift_Concurrency.tbd", 'sdk/sysroot_fe4/usr/lib/swift/libswift_Concurrency.tbd' ],
        [ "$sysroot/usr/lib/swift/libswiftObjectiveC.tbd", 'sdk/sysroot_fe4/usr/lib/swift/libswiftObjectiveC.tbd' ],
        [ "$sysroot/usr/lib/swift/libswiftDarwin.tbd", 'sdk/sysroot_fe4/usr/lib/swift/libswiftDarwin.tbd' ],
        [ "$sysroot/usr/lib/swift/libswift_StringProcessing.tbd", 'sdk/sysroot_fe4/usr/lib/swift/libswift_StringProcessing.tbd' ],
        [ "$sysroot/usr/lib/swift/libswiftSynchronization.tbd", 'sdk/sysroot_fe4/usr/lib/swift/libswiftSynchronization.tbd' ],
    );
    for my $required (@required_tbd) {
        fail("missing named linker input $required->[0]") unless lstat($required->[0]);
        push @records, join("\t", 'required-linker-input', $required->[1]);
    }

    my %seen;
    for my $record (@records) {
        next unless $record =~ /^node\t[^\t]+\t[^\t]+\t(.+)$/;
        fail("duplicate inventory path $1") if $seen{$1}++;
    }
    print "format\tfocus-widget-build-inputs-v2\n";
    print "$_\n" for sort @records;
}

sub capture_command {
    my (@command) = @_;
    open my $fh, '-|', @command or fail("cannot execute $command[0]: $!");
    local $/;
    my $output = <$fh>;
    $output = '' unless defined $output;
    close $fh or fail("command failed: @command");
    return $output;
}

sub macho_commands {
    my ($otool, $path) = @_;
    my $text = capture_command($otool, '-l', $path);
    my (@dependencies, @rpaths);
    my $command = '';
    for my $line (split /\n/, $text) {
        if ($line =~ /^\s*cmd\s+(LC_[A-Z0-9_]+)/) {
            $command = $1;
            next;
        }
        if ($command eq 'LC_RPATH' && $line =~ /^\s*path\s+(.+?)\s+\(offset\s+\d+\)\s*$/) {
            push @rpaths, $1;
            $command = '';
            next;
        }
        if ($command =~ /^(LC_LOAD_DYLIB|LC_LOAD_WEAK_DYLIB|LC_REEXPORT_DYLIB|LC_LOAD_UPWARD_DYLIB|LC_LAZY_LOAD_DYLIB)$/
                && $line =~ /^\s*name\s+(.+?)\s+\(offset\s+\d+\)\s*$/) {
            push @dependencies, [ $1, $command eq 'LC_LOAD_WEAK_DYLIB' ? 1 : 0, $command ];
            $command = '';
        }
    }
    return (\@dependencies, \@rpaths);
}

sub normalize_absolute {
    my ($path) = @_;
    fail("expected absolute path, got $path") unless $path =~ m{^/};
    my @parts;
    for my $part (split m{/+}, $path) {
        next if $part eq '' || $part eq '.';
        if ($part eq '..') { pop @parts if @parts; next; }
        push @parts, $part;
    }
    return '/' . join('/', @parts);
}

sub beneath {
    my ($path, $root) = @_;
    return $path eq $root || index($path, "$root/") == 0;
}

sub require_directory_no_link {
    my ($path, $what) = @_;
    my @st = lstat($path);
    fail("missing $what: $path") unless @st;
    fail("$what is a symlink: $path") if -l _;
    fail("$what is not a directory: $path") unless -d _;
}

sub require_regular_beneath_no_links {
    my ($path, $root, $what) = @_;
    fail("$what is outside its trusted root $root: $path") unless beneath($path, $root);
    fail("$what is the trusted root directory, not a file: $path") if $path eq $root;
    require_directory_no_link($root, "$what trusted root");

    my $relative = substr($path, length($root));
    $relative =~ s{^/}{};
    my @parts = split m{/}, $relative;
    my $cursor = $root;
    for my $index (0 .. $#parts) {
        $cursor .= "/$parts[$index]";
        my @st = lstat($cursor);
        fail("missing $what path component: $cursor") unless @st;
        fail("$what path component is a symlink: $cursor") if -l _;
        if ($index == $#parts) {
            fail("$what is not a regular file: $cursor") unless -f _;
        } else {
            fail("$what ancestor is not a directory: $cursor") unless -d _;
        }
    }
}

sub runtime_path {
    my ($dyld_path, $guest_root) = @_;
    return normalize_absolute("$guest_root/darwin$dyld_path");
}

sub expand_runtime_token {
    my ($token, $image, $executable, $guest_root) = @_;
    if ($token =~ m{^/}) {
        return runtime_path($token, $guest_root);
    }
    if ($token =~ m{^\@loader_path(?:/(.*))?$}) {
        return normalize_absolute(dirname($image) . '/' . (defined($1) ? $1 : ''));
    }
    if ($token =~ m{^\@executable_path(?:/(.*))?$}) {
        return normalize_absolute(dirname($executable) . '/' . (defined($1) ? $1 : ''));
    }
    fail("unsupported runtime token $token in $image");
}

sub runtime_label {
    my ($path, $executable, $package, $guest_root) = @_;
    return 'executable/' . basename($executable) if $path eq $executable;
    if (beneath($path, $guest_root)) {
        my $rel = substr($path, length($guest_root)); $rel =~ s{^/}{};
        return "guest-root/$rel";
    }
    if (beneath($path, $package)) {
        my $rel = substr($path, length($package)); $rel =~ s{^/}{};
        return "package/$rel";
    }
    fail("resolved runtime image is outside executable/package/root: $path");
}

sub require_regular_no_link {
    my ($path, $what) = @_;
    my @st = lstat($path);
    fail("missing $what: $path") unless @st;
    fail("$what is a symlink: $path") if -l _;
    fail("$what is not a regular file: $path") unless -f _;
}

sub require_runtime_image {
    my ($path, $executable, $package, $guest_root, $what) = @_;
    if ($path eq $executable) {
        require_regular_beneath_no_links($path, dirname($executable), $what);
    } elsif (beneath($path, $guest_root)) {
        require_regular_beneath_no_links($path, $guest_root, $what);
    } elsif (beneath($path, $package)) {
        require_regular_beneath_no_links($path, $package, $what);
    } else {
        fail("$what is outside executable/package/root: $path");
    }
}

sub closure_command {
    my (@args) = @_;
    my ($otool, $executable, $package, $guest_root);
    GetOptionsFromArray(
        \@args,
        'otool=s'      => \$otool,
        'executable=s' => \$executable,
        'package=s'    => \$package,
        'guest-root=s' => \$guest_root,
    ) or fail('invalid closure options');
    fail('closure takes no positional arguments') if @args;
    fail('closure requires --otool, --executable, --package, and --guest-root')
        unless defined($otool) && defined($executable) && defined($package) && defined($guest_root);
    $executable = normalize_absolute($executable);
    $package = normalize_absolute($package);
    $guest_root = normalize_absolute($guest_root);
    require_directory_no_link($package, 'framework package');
    require_directory_no_link($guest_root, 'guest root');
    require_runtime_image($executable, $executable, $package, $guest_root, 'guest executable');

    my @queue = ([ $executable, [] ]);
    my (%processed_state, %files, %edges);
    while (@queue) {
        my ($image, $inherited) = @{shift @queue};
        require_runtime_image($image, $executable, $package, $guest_root, 'runtime closure image');
        my $state_key = join("\0", $image, @$inherited);
        next if $processed_state{$state_key}++;
        fail('runtime closure exceeded 4096 resolution states') if keys(%processed_state) > 4096;
        my $label = runtime_label($image, $executable, $package, $guest_root);
        $files{$label} = file_sha256($image);
        my ($dependencies, $raw_rpaths) = macho_commands($otool, $image);
        my @rpaths;
        for my $raw (@$raw_rpaths) {
            my $expanded = expand_runtime_token($raw, $image, $executable, $guest_root);
            push @rpaths, $expanded unless grep { $_ eq $expanded } @rpaths;
        }
        push @rpaths, grep {
            my $candidate = $_;
            !grep { $_ eq $candidate } @rpaths;
        } @$inherited;

        for my $dependency (@$dependencies) {
            my ($name, $weak, $kind) = @$dependency;
            clean_field($name, 'Mach-O load path');
            my @candidates;
            if ($name =~ m{^\@rpath/(.+)$}) {
                my $suffix = $1;
                for my $rpath (@rpaths) {
                    my $candidate = normalize_absolute("$rpath/$suffix");
                    push @candidates, $candidate if lstat($candidate);
                }
            } else {
                my $candidate = expand_runtime_token($name, $image, $executable, $guest_root);
                push @candidates, $candidate if lstat($candidate);
            }
            my %unique = map { $_ => 1 } @candidates;
            @candidates = sort keys %unique;
            if (!@candidates && $weak) {
                $edges{join("\t", 'weak-missing', $label, $kind, $name)} = 1;
                next;
            }
            fail("cannot resolve $kind $name required by $label") unless @candidates;
            fail("ambiguous resolution of $name required by $label: @candidates") if @candidates > 1;
            my $resolved = $candidates[0];
            require_runtime_image(
                $resolved, $executable, $package, $guest_root, "resolved $kind $name");
            my $target_label = runtime_label($resolved, $executable, $package, $guest_root);
            $edges{join("\t", 'edge', $label, $kind, $name, $target_label)} = 1;
            push @queue, [ $resolved, [ @rpaths ] ];
        }
    }

    my $loader = "$guest_root/machorun";
    my $root_manifest = "$guest_root/.manifest";
    require_regular_beneath_no_links($loader, $guest_root, 'machorun loader');
    require_regular_beneath_no_links($root_manifest, $guest_root, 'guest-root manifest');
    $files{'loader/machorun'} = file_sha256($loader);
    $files{'attestation/guest-root.manifest'} = file_sha256($root_manifest);

    for my $stub (
        'guest-root/darwin/System/Library/Frameworks/Foundation.framework/Foundation',
        'guest-root/darwin/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation',
    ) {
        fail("known substrate stub is absent from recursive closure: $stub")
            unless exists $files{$stub};
    }

    print "format\tfocus-widget-runtime-closure-v2\n";
    print join("\t", 'file', $_, $files{$_}), "\n" for sort keys %files;
    print "$_\n" for sort keys %edges;
}

my @FRAMEWORK_MODULES = (
    [ 'SwiftUI', 7 ],
    [ 'OpenUIKit', 9 ],
    [ 'OpenCoreGraphics', 16 ],
    [ 'FoundationEssentials', 20 ],
    [ 'Combine', 7 ],
    [ 'OpenCombine', 11 ],
);

sub objc_swift_module {
    my ($symbol) = @_;
    my $class_tail;
    if ($symbol =~ /^_OBJC_(?:CLASS|METACLASS)_\$__TtC(.*)\z/) {
        $class_tail = $1;
    } elsif ($symbol =~ /^_OBJC_IVAR_\$__TtC(.*)\.[A-Za-z_][A-Za-z0-9_]*\z/) {
        # IVAR records append a canonical Objective-C `.ivarName` to the
        # complete Swift runtime class name.  Split it before parsing the
        # length-prefixed class production.
        $class_tail = $1;
    } else {
        return undef;
    }

    # This proof deliberately supports the emitted old-mangling nominal-type
    # subset only: the initial class marker is in `_TtC`; each following C/O/V
    # marker introduces one nested nominal context.  The remainder must be
    # exactly module + those contexts + final type, each encoded as a decimal
    # byte length and an ASCII identifier.  Parsing the lengths prevents a
    # partial demangle or a misleading suffix from claiming module ownership.
    $class_tail =~ s/^([COV]*)//;
    my $nested_count = length($1);
    my @identifiers;
    for (1 .. $nested_count + 2) {
        return undef unless $class_tail =~ s/^([1-9][0-9]*)//;
        my $byte_count = 0 + $1;
        return undef if length($class_tail) < $byte_count;
        my $identifier = substr($class_tail, 0, $byte_count, '');
        return undef
            unless $identifier =~ /^[A-Za-z_][A-Za-z0-9_]*\z/;
        push @identifiers, $identifier;
    }
    return undef unless length($class_tail) == 0;

    for my $entry (@FRAMEWORK_MODULES) {
        my ($module, $length) = @$entry;
        return $module
            if $identifiers[0] eq $module && length($identifiers[0]) == $length;
    }
    return undef;
}

sub objc_classifier_selftest {
    my @positive = (
        [ '_OBJC_CLASS_$__TtC9OpenUIKit11UITextRange', 'OpenUIKit' ],
        [ '_OBJC_METACLASS_$__TtC7SwiftUI10_UIHosting', 'SwiftUI' ],
        [ '_OBJC_IVAR_$__TtC16OpenCoreGraphics7Storage.value', 'OpenCoreGraphics' ],
        [ '_OBJC_CLASS_$__TtCC9OpenUIKit5Outer5Inner', 'OpenUIKit' ],
        [ '_OBJC_METACLASS_$__TtCO7Combine5Outer5Inner', 'Combine' ],
        [ '_OBJC_IVAR_$__TtCV11OpenCombine5Outer5Inner.value', 'OpenCombine' ],
        # A real earlier module owns this symbol; the later type spelling must
        # never be mistaken for an OpenUIKit module prefix.
        [ '_OBJC_CLASS_$__TtC7SwiftUI9OpenUIKit', 'SwiftUI' ],
    );
    for my $fixture (@positive) {
        my ($symbol, $expected) = @$fixture;
        my $actual = objc_swift_module($symbol);
        fail("ObjC classifier expected $expected for $symbol")
            unless defined($actual) && $actual eq $expected;
    }

    my @negative = (
        'junk_OBJC_CLASS_$__TtC9OpenUIKit11UITextRange',
        '_OBJC_CLASS_$_misleading__TtC9OpenUIKit11UITextRange',
        '_OBJC_CLASS_$__TtV9OpenUIKit11UITextRange',
        '_OBJC_CLASS_$__TtCX9OpenUIKit11UITextRange',
        '_OBJC_EHTYPE_$__TtC9OpenUIKit11UITextRange',
        '_OBJC_IVAR_$__TtC9OpenUIKit11UITextRange',
        '_OBJC_CLASS_$__TtC9OpenUIKit',
        '_OBJC_CLASS_$__TtC9OpenUIKitUITextRange',
        '_OBJC_CLASS_$__TtC9OpenUIKit11UITextRange.evil',
        '_OBJC_CLASS_$__TtC9OpenUIKit99X',
        '_OBJC_CLASS_$__TtC9OpenUIKit5Outer5Inner',
        '_OBJC_CLASS_$__TtCC9OpenUIKit5Outer',
        '_OBJC_CLASS_$__TtC5Other9OpenUIKit',
    );
    for my $symbol (@negative) {
        my $actual = objc_swift_module($symbol);
        fail("ObjC classifier unexpectedly accepted $symbol as $actual")
            if defined $actual;
    }

    print 'OBJC_CLASSIFIER_SELFTEST_OK positives=', scalar(@positive),
        ' negatives=', scalar(@negative), "\n";
}

sub conformance_classifier_selftest {
    my (@args) = @_;
    my $demangle = 'swift-demangle';
    GetOptionsFromArray(\@args, 'demangle=s' => \$demangle)
        or fail('invalid conformance-classifier-selftest options');
    fail('conformance-classifier-selftest takes no positional arguments') if @args;
    fail('conformance-classifier-selftest requires --demangle')
        unless defined($demangle) && length $demangle;

    my %definition_owner = (
        SwiftUI => 'libSwiftUI',
        OpenUIKit => 'libOpenUIKit',
        OpenCoreGraphics => 'libOpenCoreGraphics',
        FoundationEssentials => 'libFoundationEssentials',
        Combine => 'libCombine',
        OpenCombine => 'libOpenCombine',
    );

    # Authority reverse-ownership failures on the same SwiftUI extension of
    # OpenCoreGraphics.CGFloat: Mc/WP/Wp for `_OpenVectorArithmetic` (main
    # 8e12b714) and the property descriptor `MV` for `magnitudeSquared`
    # (main 473b3860). Extension members are SwiftUI's, not the type's.
    my @positive = (
        [
            '_$s16OpenCoreGraphics7CGFloatV7SwiftUI01_A16VectorArithmeticADMc',
            'SwiftUI',
            'libSwiftUI',
        ],
        [
            '_$s16OpenCoreGraphics7CGFloatV7SwiftUI01_A16VectorArithmeticADWP',
            'SwiftUI',
            'libSwiftUI',
        ],
        [
            '_$s16OpenCoreGraphics7CGFloatV7SwiftUI01_A16VectorArithmeticADWp',
            'SwiftUI',
            'libSwiftUI',
        ],
        [
            '_$s16OpenCoreGraphics7CGFloatV7SwiftUIE16magnitudeSquaredSdvpMV',
            'SwiftUI',
            'libSwiftUI',
        ],
        # TextAttributes.swift `extension AttributeScopes { var swiftUI }`.
        # Compact demangle uses Double as a parseable value encoding; ARM64
        # may emit the nested SwiftUIAttributes metatype. Owner is the
        # `(extension in SwiftUI):` clause either way.
        [
            '_$s20FoundationEssentials15AttributeScopesO7SwiftUIE7swiftUISdvpMV',
            'SwiftUI',
            'libSwiftUI',
        ],
        [
            '_$s20FoundationEssentials15AttributeScopesO7SwiftUIE7swiftUISdvg',
            'SwiftUI',
            'libSwiftUI',
        ],
        [
            '_$s20FoundationEssentials22AttributeDynamicLookupO7SwiftUIEyxqd__cluig',
            'SwiftUI',
            'libSwiftUI',
        ],
    );
    for my $fixture (@positive) {
        my ($symbol, $expected_module, $defining_image) = @$fixture;
        my ($actual) = classify_framework_symbol($demangle, $symbol);
        fail("conformance classifier expected $expected_module for $symbol, got "
            . (defined $actual ? $actual : 'undef'))
            unless defined($actual) && $actual eq $expected_module;
        fail("reverse ownership rejected defining image $defining_image for $symbol")
            unless $definition_owner{$actual} eq $defining_image;
    }

    # Nominal type descriptors for the foreign CGFloat / AttributeScopes types:
    # still owned by OpenCoreGraphics / FoundationEssentials. libSwiftUI
    # defining them must keep failing.
    my @negative = (
        [ '_$s16OpenCoreGraphics7CGFloatVMn', 'OpenCoreGraphics', 'libSwiftUI' ],
        [
            '_$s20FoundationEssentials15AttributeScopesOMn',
            'FoundationEssentials',
            'libSwiftUI',
        ],
    );
    for my $fixture (@negative) {
        my ($symbol, $expected_module, $wrong_image) = @$fixture;
        my ($actual) = classify_framework_symbol($demangle, $symbol);
        fail("foreign classifier expected $expected_module for $symbol, got "
            . (defined $actual ? $actual : 'undef'))
            unless defined($actual) && $actual eq $expected_module;
        fail("reverse ownership failed to reject $wrong_image defining $actual symbol $symbol")
            if $definition_owner{$actual} eq $wrong_image;
    }

    print 'CONFORMANCE_CLASSIFIER_SELFTEST_OK positives=', scalar(@positive),
        ' negatives=', scalar(@negative), "\n";
}

sub prefixed_swift_module {
    my ($symbol) = @_;
    return 'SwiftUI' if $symbol =~ /^_?\$s7SwiftUI/;
    return 'OpenUIKit' if $symbol =~ /^_?\$s9OpenUIKit/;
    return 'OpenCoreGraphics' if $symbol =~ /^_?\$s16OpenCoreGraphics/;
    return 'FoundationEssentials' if $symbol =~ /^_?\$s20FoundationEssentials/;
    return 'Combine' if $symbol =~ /^_?\$s7Combine/;
    return 'OpenCombine' if $symbol =~ /^_?\$s11OpenCombine/;
    my $objc_module = objc_swift_module($symbol);
    return $objc_module if defined $objc_module;
    return undef;
}

sub framework_tokens {
    my ($symbol) = @_;
    return grep { index($symbol, length($_) . $_) >= 0 }
        qw(SwiftUI OpenUIKit OpenCoreGraphics FoundationEssentials Combine OpenCombine);
}

sub demangle_compact {
    my ($demangle, $symbol) = @_;
    my $expanded = capture_command($demangle, '--compact', $symbol);
    $expanded =~ s/[\r\n]+\z//;
    fail("demangler returned multiple lines for $symbol") if $expanded =~ /[\r\n]/;
    return $expanded;
}

# Owning module from compact demangle, in this order:
#   1. `(extension in M):` anywhere → M (SwiftUI's CGFloat.magnitudeSquared MV,
#      AttributeScopes.swiftUI, AttributeDynamicLookup subscript; compact form
#      is often `property descriptor for (extension in SwiftUI):…`, not leading)
#   2. `… : M.Protocol in M2` conformance/witness (Mc/WP/Wp) → protocol module M
#   3. otherwise undef (caller falls back to the leading nominal-type module)
sub owning_module_from_demangle {
    my ($expanded) = @_;
    return undef unless defined $expanded && length $expanded;
    my $modules = join('|', map { quotemeta($_->[0]) } @FRAMEWORK_MODULES);
    return $1 if $expanded =~ /\(extension in ($modules)\):/;
    return $1 if $expanded =~
        /^(?:protocol conformance descriptor|protocol witness table(?: pattern)?) for .+ : ($modules)\./;
    return undef;
}

sub classify_framework_symbol {
    my ($demangle, $symbol) = @_;
    my $prefix = prefixed_swift_module($symbol);
    my @mentioned = framework_tokens($symbol);
    return (undef, undef) unless defined $prefix || @mentioned;

    my $expanded = demangle_compact($demangle, $symbol);
    my $from_demangle = owning_module_from_demangle($expanded);
    return ($from_demangle, $expanded) if defined $from_demangle;
    return ($prefix, $expanded) if defined $prefix;

    my @owners;
    for my $module (qw(SwiftUI OpenUIKit OpenCoreGraphics FoundationEssentials Combine OpenCombine)) {
        push @owners, $module
            if $expanded =~ /^associated type descriptor for \Q$module\E\./
            || $expanded =~ /\bin \Q$module\E\z/;
    }
    fail("ambiguous framework owner [@owners] for $symbol ($expanded)") if @owners > 1;
    fail("unclassified framework-bearing symbol $symbol ($expanded)") unless @owners == 1;
    return ($owners[0], $expanded);
}

sub symbol_records {
    my ($demangle, $text) = @_;
    my @records;
    for my $line (split /\n/, $text) {
        my @fields = split /\s+/, $line;
        next unless @fields;
        my $symbol = $fields[-1];
        my ($module, $expanded) = classify_framework_symbol($demangle, $symbol);
        push @records, [ $symbol, $module, $expanded ] if defined $module;
    }
    return @records;
}

sub provider_command {
    my (@args) = @_;
    my ($nm, $objdump, $demangle, $openuikit, $opencoregraphics, $swiftui,
        $foundationessentials, $combine, $opencombine, $executable);
    GetOptionsFromArray(
        \@args,
        'nm=s'         => \$nm,
        'objdump=s'    => \$objdump,
        'demangle=s'   => \$demangle,
        'openuikit=s'  => \$openuikit,
        'opencoregraphics=s' => \$opencoregraphics,
        'swiftui=s'    => \$swiftui,
        'foundationessentials=s' => \$foundationessentials,
        'combine=s'    => \$combine,
        'opencombine=s' => \$opencombine,
        'executable=s' => \$executable,
    ) or fail('invalid provider options');
    fail('providers takes no positional arguments') if @args;
    fail('providers requires --nm, --objdump, --demangle, --openuikit, --opencoregraphics, --swiftui, --foundationessentials, --combine, --opencombine, and --executable')
        unless defined($nm) && defined($objdump) && defined($demangle) && defined($openuikit)
            && defined($opencoregraphics) && defined($swiftui)
            && defined($foundationessentials)
            && defined($combine) && defined($opencombine)
            && defined($executable);

    my %paths = (
        libOpenUIKit => $openuikit,
        libOpenCoreGraphics => $opencoregraphics,
        libSwiftUI => $swiftui,
        libFoundationEssentials => $foundationessentials,
        libCombine => $combine,
        libOpenCombine => $opencombine,
        executable => $executable,
    );
    require_regular_no_link($paths{$_}, "provider image $_") for keys %paths;
    # OpenCombine's literal Combine compatibility image re-exports the
    # implementation. Two-level client binds therefore name libCombine while
    # the actual definitions live in libOpenCombine; audit both facts.
    my %expected_bind_provider = (
        SwiftUI => 'libSwiftUI',
        OpenUIKit => 'libOpenUIKit',
        OpenCoreGraphics => 'libOpenCoreGraphics',
        FoundationEssentials => 'libFoundationEssentials',
        Combine => 'libCombine',
        OpenCombine => 'libCombine',
    );
    my %definition_owner = (
        SwiftUI => 'libSwiftUI',
        OpenUIKit => 'libOpenUIKit',
        OpenCoreGraphics => 'libOpenCoreGraphics',
        FoundationEssentials => 'libFoundationEssentials',
        Combine => 'libCombine',
        OpenCombine => 'libOpenCombine',
    );
    my (%definitions, %undefined, %binds, %counts, %symbol_module);
    for my $image (sort keys %paths) {
        my @defined = symbol_records(
            $demangle, capture_command($nm, '-gj', '--defined-only', $paths{$image}));
        my @undefined = symbol_records($demangle, capture_command($nm, '-u', $paths{$image}));
        for my $record (@defined) {
            my ($symbol, $module) = @$record;
            $definitions{$image}{$symbol} = 1;
            $symbol_module{$symbol} = $module;
            $counts{$image}{defined}{$module}++;
        }
        for my $record (@undefined) {
            my ($symbol, $module) = @$record;
            $undefined{$image}{$symbol} = 1;
            $symbol_module{$symbol} = $module unless exists $symbol_module{$symbol};
            $counts{$image}{undefined}{$module}++;
        }
        for my $mode ('--bind', '--lazy-bind', '--weak-bind') {
            my $text = capture_command($objdump, '--macho', $mode, $paths{$image});
            for my $line (split /\n/, $text) {
                my @fields = split /\s+/, $line;
                next unless @fields >= 2;
                my $symbol = $fields[-1];
                my ($module) = classify_framework_symbol($demangle, $symbol);
                next unless defined $module;
                $symbol_module{$symbol} = $module unless exists $symbol_module{$symbol};
                my $provider = $fields[-2];
                $binds{$image}{$symbol}{$provider} = 1;
            }
        }
    }

    for my $image (sort keys %paths) {
        for my $symbol (sort keys %{$definitions{$image} || {}}) {
            my $module = $symbol_module{$symbol};
            fail("reverse ownership violation: $image defines $module symbol $symbol")
                unless $definition_owner{$module} eq $image;
        }
        for my $symbol (sort keys %{$undefined{$image} || {}}) {
            my $module = $symbol_module{$symbol};
            my $expected = $expected_bind_provider{$module};
            fail("provider image $image imports its own $module symbol $symbol")
                if $expected eq $image;
            my @providers = sort keys %{$binds{$image}{$symbol} || {}};
            fail("no two-level bind for $image undefined $symbol") unless @providers;
            fail("$image undefined $symbol binds to [@providers], expected exactly $expected")
                unless @providers == 1 && $providers[0] eq $expected;
            my $owner = $definition_owner{$module};
            fail("$owner does not define imported symbol $symbol")
                unless $definitions{$owner}{$symbol};
        }
        for my $symbol (sort keys %{$binds{$image} || {}}) {
            fail("bind table contains framework symbol absent from undefined table: $image $symbol")
                unless $undefined{$image}{$symbol};
            my $module = $symbol_module{$symbol};
            my $expected = $expected_bind_provider{$module};
            my @providers = sort keys %{$binds{$image}{$symbol}};
            fail("noncanonical provider for $image $symbol: [@providers], expected exactly $expected")
                unless @providers == 1 && $providers[0] eq $expected;
        }
    }

    for my $need (
        [ 'libOpenUIKit', 'defined', 'OpenUIKit' ],
        [ 'libOpenCoreGraphics', 'defined', 'OpenCoreGraphics' ],
        [ 'libOpenUIKit', 'undefined', 'OpenCoreGraphics' ],
        [ 'libSwiftUI', 'defined', 'SwiftUI' ],
        [ 'libOpenCombine', 'defined', 'OpenCombine' ],
        [ 'libSwiftUI', 'undefined', 'OpenUIKit' ],
        [ 'libSwiftUI', 'undefined', 'OpenCoreGraphics' ],
        [ 'libFoundationEssentials', 'defined', 'FoundationEssentials' ],
        [ 'libSwiftUI', 'undefined', 'FoundationEssentials' ],
        [ 'libSwiftUI', 'undefined', 'OpenCombine' ],
        [ 'executable', 'undefined', 'SwiftUI' ],
        [ 'executable', 'undefined', 'OpenUIKit' ],
        [ 'executable', 'undefined', 'OpenCoreGraphics' ],
    ) {
        fail("vacuous provider gate: no $need->[2] $need->[1] symbols in $need->[0]")
            unless ($counts{$need->[0]}{$need->[1]}{$need->[2]} || 0) > 0;
    }

    print "format\tfocus-widget-framework-providers-v2\n";
    for my $image (sort keys %paths) {
        for my $kind (qw(defined undefined)) {
            for my $module (qw(SwiftUI OpenUIKit OpenCoreGraphics FoundationEssentials Combine OpenCombine)) {
                printf "count\t%s\t%s\t%s\t%d\n", $image, $kind, $module,
                    ($counts{$image}{$kind}{$module} || 0);
            }
        }
        for my $symbol (sort keys %{$definitions{$image} || {}}) {
            print join("\t", 'definition', $image, $symbol_module{$symbol}, $symbol), "\n";
        }
        for my $symbol (sort keys %{$undefined{$image} || {}}) {
            my ($provider) = keys %{$binds{$image}{$symbol}};
            print join("\t", 'import', $image, $symbol_module{$symbol}, $provider, $symbol), "\n";
        }
    }
}

my $command = shift @ARGV // '';
if ($command eq 'inventory') {
    inventory_command(@ARGV);
} elsif ($command eq 'closure') {
    closure_command(@ARGV);
} elsif ($command eq 'providers') {
    provider_command(@ARGV);
} elsif ($command eq 'objc-classifier-selftest') {
    objc_classifier_selftest(@ARGV);
} elsif ($command eq 'conformance-classifier-selftest') {
    conformance_classifier_selftest(@ARGV);
} else {
    fail('usage: focus_widget_guest_attest.pl inventory|closure|providers|objc-classifier-selftest|conformance-classifier-selftest [options]');
}
