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
    my ($w, $uikit, $full, $sysroot);
    GetOptionsFromArray(
        \@args,
        'w=s'       => \$w,
        'uikit=s'   => \$uikit,
        'full=s'    => \$full,
        'sysroot=s' => \$sysroot,
    ) or fail('invalid inventory options');
    fail('inventory takes no positional arguments') if @args;
    fail('inventory requires --w, --uikit, --full, and --sysroot')
        unless defined($w) && defined($uikit) && defined($full) && defined($sysroot);

    my @records;
    my @files = (
        [ "$w/full/swiftui/build_focus_widget_guest.sh", 'project/full/swiftui/build_focus_widget_guest.sh' ],
        [ "$w/full/swiftui/focus_widget_guest_attest.pl", 'project/full/swiftui/focus_widget_guest_attest.pl' ],
        [ "$w/full/swiftui/FocusWidgetBundle.generated.swift", 'project/full/swiftui/FocusWidgetBundle.generated.swift' ],
        [ "$w/full/swiftui/FocusWidgetGuestMain.swift", 'project/full/swiftui/FocusWidgetGuestMain.swift' ],
        [ "$w/full/scripts/build_full.sh", 'project/full/scripts/build_full.sh' ],
        [ "$w/full/scripts/uihelpers_subject.sh", 'project/full/scripts/uihelpers_subject.sh' ],
        [ "$w/scripts/require_fresh_root.sh", 'project/scripts/require_fresh_root.sh' ],
        [ "$w/scripts/macho_same_except_id.pl", 'project/scripts/macho_same_except_id.pl' ],
        [ "$full/guard_no_foundation.swift", 'build-full/guard_no_foundation.swift' ],
        [ "$full/uihelpers-subject.sha256", 'build-full/uihelpers-subject.sha256' ],
        map({ [ "$full/$_", "build-full/$_" ] }
            qw(openuikit.o opencoregraphics.o cportableio.o cstbtruetype.o
               hostclock.o swiftcorepatch.o)),
        map({ [ "$full/OpenUIKit.$_", "build-full/OpenUIKit.$_" ] }
            qw(swiftmodule swiftdoc swiftsourceinfo abi.json)),
        map({ [ "$full/OpenCoreGraphics.$_", "build-full/OpenCoreGraphics.$_" ] }
            qw(swiftmodule swiftdoc swiftsourceinfo abi.json)),
        [ "$uikit/Sources/SwiftUI/Values.swift", 'openuikit/Sources/SwiftUI/Values.swift' ],
        [ "$uikit/Sources/SwiftUI/View.swift", 'openuikit/Sources/SwiftUI/View.swift' ],
        [ "$uikit/Sources/SwiftUI/Hosting.swift", 'openuikit/Sources/SwiftUI/Hosting.swift' ],
    );
    push @records, node_record($_->[0], $_->[1]) for @files;

    my @trees = (
        [ "$full/inc/CPortableIO", 'build-full/inc/CPortableIO' ],
        [ "$full/inc/CSTBTrueType", 'build-full/inc/CSTBTrueType' ],
        [ "$w/full/hostclock/include", 'project/full/hostclock/include' ],
        [ "$uikit/Sources/CQuartz/include", 'openuikit/Sources/CQuartz/include' ],
        [ $sysroot, 'sdk/sysroot_full' ],
    );
    inventory_tree($_->[0], $_->[1], \@records) for @trees;

    my @required_tbd = (
        [ "$sysroot/usr/lib/swift/libswiftCore.tbd", 'sdk/sysroot_full/usr/lib/swift/libswiftCore.tbd' ],
        [ "$sysroot/usr/lib/libSystem.tbd", 'sdk/sysroot_full/usr/lib/libSystem.tbd' ],
        [ "$sysroot/usr/lib/libobjc.tbd", 'sdk/sysroot_full/usr/lib/libobjc.tbd' ],
        [ "$sysroot/usr/lib/swift/libswift_Concurrency.tbd", 'sdk/sysroot_full/usr/lib/swift/libswift_Concurrency.tbd' ],
        [ "$sysroot/usr/lib/swift/libswiftObjectiveC.tbd", 'sdk/sysroot_full/usr/lib/swift/libswiftObjectiveC.tbd' ],
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
    if (beneath($path, $package)) {
        my $rel = substr($path, length($package)); $rel =~ s{^/}{};
        return "package/$rel";
    }
    if (beneath($path, $guest_root)) {
        my $rel = substr($path, length($guest_root)); $rel =~ s{^/}{};
        return "guest-root/$rel";
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
    } elsif (beneath($path, $package)) {
        require_regular_beneath_no_links($path, $package, $what);
    } elsif (beneath($path, $guest_root)) {
        require_regular_beneath_no_links($path, $guest_root, $what);
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

sub prefixed_swift_module {
    my ($symbol) = @_;
    return 'SwiftUI' if $symbol =~ /^_?\$s7SwiftUI/;
    return 'OpenUIKit' if $symbol =~ /^_?\$s9OpenUIKit/;
    return 'OpenCoreGraphics' if $symbol =~ /^_?\$s16OpenCoreGraphics/;
    return undef;
}

sub framework_tokens {
    my ($symbol) = @_;
    return grep { index($symbol, length($_) . $_) >= 0 }
        qw(SwiftUI OpenUIKit OpenCoreGraphics);
}

sub classify_framework_symbol {
    my ($demangle, $symbol) = @_;
    my $prefix = prefixed_swift_module($symbol);
    return ($prefix, undef) if defined $prefix;

    my @mentioned = framework_tokens($symbol);
    return (undef, undef) unless @mentioned;
    my $expanded = capture_command($demangle, '--compact', $symbol);
    $expanded =~ s/[\r\n]+\z//;
    fail("demangler returned multiple lines for $symbol") if $expanded =~ /[\r\n]/;
    my @owners;
    for my $module (qw(SwiftUI OpenUIKit OpenCoreGraphics)) {
        push @owners, $module
            if $expanded =~ /\(extension in \Q$module\E\):/
            || $expanded =~ /^associated type descriptor for \Q$module\E\./
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
    my ($nm, $objdump, $demangle, $openuikit, $swiftui, $executable);
    GetOptionsFromArray(
        \@args,
        'nm=s'         => \$nm,
        'objdump=s'    => \$objdump,
        'demangle=s'   => \$demangle,
        'openuikit=s'  => \$openuikit,
        'swiftui=s'    => \$swiftui,
        'executable=s' => \$executable,
    ) or fail('invalid provider options');
    fail('providers takes no positional arguments') if @args;
    fail('providers requires --nm, --objdump, --demangle, --openuikit, --swiftui, and --executable')
        unless defined($nm) && defined($objdump) && defined($demangle) && defined($openuikit)
            && defined($swiftui) && defined($executable);

    my %paths = (
        libOpenUIKit => $openuikit,
        libSwiftUI => $swiftui,
        executable => $executable,
    );
    require_regular_no_link($paths{$_}, "provider image $_") for keys %paths;
    my %expected_provider = (
        SwiftUI => 'libSwiftUI',
        OpenUIKit => 'libOpenUIKit',
        OpenCoreGraphics => 'libOpenUIKit',
    );
    my %allowed_owner = (
        SwiftUI => 'libSwiftUI',
        OpenUIKit => 'libOpenUIKit',
        OpenCoreGraphics => 'libOpenUIKit',
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
            $symbol_module{$symbol} = $module;
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
                $symbol_module{$symbol} = $module;
                my $provider = $fields[-2];
                $binds{$image}{$symbol}{$provider} = 1;
            }
        }
    }

    for my $image (sort keys %paths) {
        for my $symbol (sort keys %{$definitions{$image} || {}}) {
            my $module = $symbol_module{$symbol};
            fail("reverse ownership violation: $image defines $module symbol $symbol")
                unless $allowed_owner{$module} eq $image;
        }
        for my $symbol (sort keys %{$undefined{$image} || {}}) {
            my $module = $symbol_module{$symbol};
            my $expected = $expected_provider{$module};
            fail("provider image $image imports its own $module symbol $symbol")
                if $expected eq $image;
            my @providers = sort keys %{$binds{$image}{$symbol} || {}};
            fail("no two-level bind for $image undefined $symbol") unless @providers;
            fail("$image undefined $symbol binds to [@providers], expected exactly $expected")
                unless @providers == 1 && $providers[0] eq $expected;
            fail("$expected does not define imported symbol $symbol")
                unless $definitions{$expected}{$symbol};
        }
        for my $symbol (sort keys %{$binds{$image} || {}}) {
            fail("bind table contains framework symbol absent from undefined table: $image $symbol")
                unless $undefined{$image}{$symbol};
            my $module = $symbol_module{$symbol};
            my $expected = $expected_provider{$module};
            my @providers = sort keys %{$binds{$image}{$symbol}};
            fail("noncanonical provider for $image $symbol: [@providers], expected exactly $expected")
                unless @providers == 1 && $providers[0] eq $expected;
        }
    }

    for my $need (
        [ 'libOpenUIKit', 'defined', 'OpenUIKit' ],
        [ 'libOpenUIKit', 'defined', 'OpenCoreGraphics' ],
        [ 'libSwiftUI', 'defined', 'SwiftUI' ],
        [ 'libSwiftUI', 'undefined', 'OpenUIKit' ],
        [ 'libSwiftUI', 'undefined', 'OpenCoreGraphics' ],
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
            for my $module (qw(SwiftUI OpenUIKit OpenCoreGraphics)) {
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
} else {
    fail('usage: focus_widget_guest_attest.pl inventory|closure|providers [options]');
}
