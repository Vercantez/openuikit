#!/usr/bin/env perl
# Fail-closed Focus/SnapKit resource-accessor provenance using only core Perl
# modules available in the pinned swift-macho-spike:noble image.

use strict;
use warnings;
use Cwd qw(abs_path);
use Digest::SHA ();
use File::Find ();
use Getopt::Long qw(GetOptionsFromArray);

sub fail { die "focus_resource_accessor_attest: $_[0]\n"; }

my %EXPECTED_HASHES = (
    'Focus/Package.swift' =>
        '2d29b769de137389f5613de6755211b255533375bf6003a2192f514e96899248',
    'Focus/Package.resolved' =>
        '632a0df0276ba7828f456ae3964f158fb7115d05f175ddf637abdd7ab4a4633b',
    'SnapKit/Package.swift' =>
        'ebb3e3c90a96e832e848e577c04b0cb9f16723c487c0efa727114d49c0a5492a',
    'SnapKit/PrivacyInfo.xcprivacy' =>
        'a07418e5fe128e224cd37964bc21c503b7aa2f575e7b4927468478ad873214fe',
    'oracle/Focus_Licenses' =>
        'a15ebd0e3c1e83ae3f8456593f1fb0c761af03e1b9742a9f34ede4c83669fe95',
    'oracle/SnapKit_SnapKit' =>
        '056cdac408eab88cced7e48cab8548c5393f6ac3040a8b0a578e77f08885b218',
);

my %FOCUS_TARGET_RESOURCES = (
    UIComponents => [],
    UIHelpers     => [],
    DesignSystem => [],
    Onboarding   => [],
    AppShortcuts => [],
    Widget       => [],
    Licenses     => ['license-list.plist', 'focus-ios.plist'],
);

sub slurp {
    my ($path) = @_;
    fail("not a regular non-symlink file: $path") unless -f $path && !-l $path;
    open my $fh, '<:raw', $path or fail("cannot read $path: $!");
    local $/;
    my $bytes = <$fh>;
    close $fh or fail("cannot close $path: $!");
    return defined($bytes) ? $bytes : '';
}

sub file_hash {
    my ($path) = @_;
    my $bytes = slurp($path);
    return Digest::SHA::sha256_hex($bytes);
}

sub require_hash {
    my ($path, $expected, $label) = @_;
    my $actual = file_hash($path);
    fail("$label hash drifted: $actual") unless $actual eq $expected;
}

sub balanced_target_calls {
    my ($text) = @_;
    my @calls;
    my $marker = '.target(';
    my $cursor = 0;
    while (1) {
        my $start = index($text, $marker, $cursor);
        last if $start < 0;
        my $index = $start + length($marker);
        my $depth = 1;
        my $in_string = 0;
        my $escaped = 0;
        while ($index < length($text) && $depth) {
            my $character = substr($text, $index, 1);
            if ($in_string) {
                if ($escaped) {
                    $escaped = 0;
                } elsif ($character eq '\\') {
                    $escaped = 1;
                } elsif ($character eq '"') {
                    $in_string = 0;
                }
            } elsif ($character eq '"') {
                $in_string = 1;
            } elsif ($character eq '(') {
                ++$depth;
            } elsif ($character eq ')') {
                --$depth;
            }
            ++$index;
        }
        fail('unterminated .target(...) declaration') if $depth;
        push @calls, substr($text, $start, $index - $start);
        $cursor = $index;
    }
    return @calls;
}

sub manifest_target_resources {
    my ($text) = @_;
    my %result;
    for my $call (balanced_target_calls($text)) {
        my ($name) = $call =~ /\bname\s*:\s*"([A-Za-z0-9_-]+)"/;
        fail('target declaration has no literal name') unless defined $name;
        fail("duplicate target declaration: $name") if exists $result{$name};
        my ($body) = $call =~ /\bresources\s*:\s*\[(.*?)\]/s;
        if (!defined $body) {
            $result{$name} = [];
            next;
        }
        my @copied = $body =~ /\.copy\(\s*"([^"\\]+)"\s*\)/g;
        my $residue = $body;
        $residue =~ s/\.copy\(\s*"[^"\\]+"\s*\)//g;
        $residue =~ s/[\s,]//g;
        fail("unsupported resource rule in target $name") if length $residue;
        $result{$name} = \@copied;
    }
    return \%result;
}

sub require_manifest_resources {
    my ($actual, $expected, $label) = @_;
    my @actual_names = sort keys %$actual;
    my @expected_names = sort keys %$expected;
    fail("$label target set drifted: @actual_names")
        unless join("\0", @actual_names) eq join("\0", @expected_names);
    for my $name (@expected_names) {
        my $actual_resources = join("\0", @{$actual->{$name}});
        my $expected_resources = join("\0", @{$expected->{$name}});
        fail("$label resources drifted for $name: $actual_resources")
            unless $actual_resources eq $expected_resources;
    }
}

sub contains {
    my ($text, $snippet) = @_;
    return index($text, $snippet) >= 0;
}

sub validate_normalized_oracle {
    my ($text, $bundle_name, $label) = @_;
    for my $snippet (
        'Bundle.main.bundleURL.appendingPathComponent',
        qq{"$bundle_name"},
        'let buildPath = "<BUILD_PATH>"',
        'let preferredBundle = Bundle(path: mainPath)',
        'preferredBundle ?? Bundle(path: buildPath)',
        'Swift.fatalError',
    ) {
        fail("$label normalized oracle lacks '$snippet'")
            unless contains($text, $snippet);
    }
    my @names = $text =~ /"([A-Za-z0-9_-]+\.bundle)"/g;
    my %names = map { $_ => 1 } @names;
    fail("$label normalized oracle bundle names drifted: @names")
        unless keys(%names) == 1 && exists $names{$bundle_name};
    my $placeholder_count = () = $text =~ /<BUILD_PATH>/g;
    fail("$label normalized oracle must contain exactly one build-path placeholder")
        unless $placeholder_count == 1;
    fail("$label normalized oracle retained an absolute temporary path")
        if $text =~ m{/(?:private/)?tmp/};
    fail("$label normalized oracle must end in exactly one appended LF")
        unless $text =~ /[^\n]\n\z/;
}

sub validate_portable_accessor {
    my ($text, $bundle_name, $label) = @_;
    for my $snippet (
        'Bundle.main.bundleURL.appendingPathComponent',
        qq{"$bundle_name"},
        'Bundle(path: mainPath)',
        'Swift.fatalError',
    ) {
        fail("$label accessor lacks '$snippet'") unless contains($text, $snippet);
    }
    for my $snippet ('Bundle.main }', "Bundle.main\n", 'buildPath', ' ?? ',
            '/private/', '/tmp/') {
        fail("$label accessor contains forbidden fallback '$snippet'")
            if contains($text, $snippet);
    }
    my @names = $text =~ /"([A-Za-z0-9_-]+\.bundle)"/g;
    my %names = map { $_ => 1 } @names;
    fail("$label accessor bundle names drifted: @names")
        unless keys(%names) == 1 && exists $names{$bundle_name};
}

sub validate_compat_accessor {
    my ($text, $bundle_name, $label) = @_;
    for my $snippet (
        'compatibility build support',
        'SWIFT_MODULE_RESOURCE_BUNDLE_UNAVAILABLE',
        'Bundle.main.bundleURL.appendingPathComponent',
        qq{"$bundle_name"},
        'Swift.fatalError',
    ) {
        fail("$label compatibility accessor lacks '$snippet'")
            unless contains($text, $snippet);
    }
    for my $snippet ('buildPath', '/private/', ' ?? ') {
        fail("$label compatibility accessor has a build-machine fallback")
            if contains($text, $snippet);
    }
}

sub validate_designsystem_trap {
    my ($text) = @_;
    for my $snippet (
        'compatibility build support',
        'declares no DesignSystem resources',
        'SWIFT_MODULE_RESOURCE_BUNDLE_UNAVAILABLE',
        'Swift.fatalError',
    ) {
        fail("DesignSystem trap lacks '$snippet'") unless contains($text, $snippet);
    }
    fail('DesignSystem compile-only trap invents a bundle identity')
        if contains($text, 'appendingPathComponent') || contains($text, '.bundle');
}

sub swiftc_invocations {
    my ($build) = @_;
    my @lines = split /\n/, $build, -1;
    my @invocations;
    for (my $index = 0; $index < @lines; ++$index) {
        next unless $lines[$index] =~ /^\s*"\$\{SWIFTC\[\@\]\}"/;
        my $invocation = $lines[$index];
        while ($invocation =~ /\\\s*\z/) {
            ++$index;
            fail('unterminated ${SWIFTC[@]} compile invocation')
                if $index >= @lines;
            $invocation .= "\n" . $lines[$index];
        }
        push @invocations, $invocation;
    }
    return @invocations;
}

sub require_compile_slice {
    my ($build, $module, $support_name) = @_;
    my @matching = grep {
        /(?:^|\s)-module-name\s+\Q$module\E(?:\s|\z)/
    } swiftc_invocations($build);
    fail("direct build does not have exactly one $module compile")
        unless @matching == 1;
    fail("$module compile omits $support_name")
        unless contains($matching[0], $support_name);
}

my @COMPILE_SUPPORT = (
    [SnapKit => 'FocusSnapKitBundle.generated.swift'],
    [DesignSystem => 'FocusDesignSystemBundle.generated.swift'],
    [Widget => 'FocusWidgetBundle.generated.swift'],
    [Onboarding => 'FocusOnboardingBundle.generated.swift'],
    [Licenses => 'FocusLicensesBundle.generated.swift'],
);

sub require_all_compile_slices {
    my ($build) = @_;
    require_compile_slice($build, @$_) for @COMPILE_SUPPORT;
}

sub upstream_conditional_hits {
    my ($focus_root, $snapkit_root) = @_;
    my @roots = (
        "$focus_root/BlockzillaPackage/Sources/DesignSystem",
        "$focus_root/BlockzillaPackage/Sources/Widget",
        "$focus_root/BlockzillaPackage/Sources/Onboarding",
        "$focus_root/BlockzillaPackage/Sources/Licenses",
        "$snapkit_root/Sources",
    );
    my @sources;
    for my $root (@roots) {
        fail("missing upstream source directory: $root") unless -d $root && !-l $root;
        File::Find::find(
            {
                no_chdir => 1,
                wanted => sub {
                    return unless /\.swift\z/ && -f $File::Find::name && !-l $File::Find::name;
                    push @sources, $File::Find::name;
                },
            },
            $root,
        );
    }
    my @hits;
    for my $source (sort @sources) {
        my $text = slurp($source);
        push @hits, $source
            if $text =~ /\bSWIFT_PACKAGE\b|\bSWIFT_MODULE_RESOURCE_BUNDLE_(?:AVAILABLE|UNAVAILABLE)\b/;
    }
    return @hits;
}

sub attest_command {
    my (@args) = @_;
    my ($focus_root, $snapkit_root, $support_root, $build_script);
    GetOptionsFromArray(
        \@args,
        'focus-root=s'  => \$focus_root,
        'snapkit-root=s' => \$snapkit_root,
        'support-root=s' => \$support_root,
        'build-script=s' => \$build_script,
    ) or fail('invalid attest options');
    fail('attest takes no positional arguments') if @args;
    fail('attest requires --focus-root, --snapkit-root, --support-root, and --build-script')
        unless defined($focus_root) && defined($snapkit_root)
            && defined($support_root) && defined($build_script);
    $focus_root = abs_path($focus_root);
    $snapkit_root = abs_path($snapkit_root);
    $support_root = abs_path($support_root);
    $build_script = abs_path($build_script);
    fail('cannot canonicalize an attest path')
        unless defined($focus_root) && defined($snapkit_root)
            && defined($support_root) && defined($build_script);

    my $focus_manifest = "$focus_root/BlockzillaPackage/Package.swift";
    my $focus_resolved = "$focus_root/Blockzilla.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved";
    my $snapkit_manifest = "$snapkit_root/Package.swift";
    my $snapkit_privacy = "$snapkit_root/Sources/PrivacyInfo.xcprivacy";
    my $oracle_root = "$support_root/full/swiftui/oracles/apple-swiftpm-6.2.1";
    my $licenses_oracle = "$oracle_root/Focus_Licenses.resource_bundle_accessor.normalized.swift.txt";
    my $snapkit_oracle = "$oracle_root/SnapKit_SnapKit.resource_bundle_accessor.normalized.swift.txt";

    for my $entry (
        [$focus_manifest, 'Focus/Package.swift'],
        [$focus_resolved, 'Focus/Package.resolved'],
        [$snapkit_manifest, 'SnapKit/Package.swift'],
        [$snapkit_privacy, 'SnapKit/PrivacyInfo.xcprivacy'],
        [$licenses_oracle, 'oracle/Focus_Licenses'],
        [$snapkit_oracle, 'oracle/SnapKit_SnapKit'],
    ) {
        require_hash($entry->[0], $EXPECTED_HASHES{$entry->[1]}, $entry->[1]);
    }

    require_manifest_resources(
        manifest_target_resources(slurp($focus_manifest)),
        \%FOCUS_TARGET_RESOURCES,
        'Focus Package.swift',
    );
    require_manifest_resources(
        manifest_target_resources(slurp($snapkit_manifest)),
        { SnapKit => ['PrivacyInfo.xcprivacy'] },
        'SnapKit Package.swift',
    );
    my $resolved = slurp($focus_resolved);
    my $pin_count = () = $resolved =~ /"package"\s*:\s*"SnapKit"/g;
    fail('Package.resolved does not contain exactly one SnapKit pin')
        unless $pin_count == 1;
    fail('Package.resolved SnapKit state drifted')
        unless $resolved =~ /"package"\s*:\s*"SnapKit".*?"state"\s*:\s*\{.*?"revision"\s*:\s*"e74fe2a978d1216c3602b129447c7301573cc2d8".*?"version"\s*:\s*"5\.7\.0"/s;

    my $licenses_oracle_text = slurp($licenses_oracle);
    my $snapkit_oracle_text = slurp($snapkit_oracle);
    validate_normalized_oracle($licenses_oracle_text, 'Focus_Licenses.bundle', 'Licenses');
    validate_normalized_oracle($snapkit_oracle_text, 'SnapKit_SnapKit.bundle', 'SnapKit');

    my %accessor_paths = (
        DesignSystem => "$support_root/full/swiftui/FocusDesignSystemBundle.generated.swift",
        Widget       => "$support_root/full/swiftui/FocusWidgetBundle.generated.swift",
        Onboarding   => "$support_root/full/swiftui/FocusOnboardingBundle.generated.swift",
        Licenses     => "$support_root/full/swiftui/FocusLicensesBundle.generated.swift",
        SnapKit      => "$support_root/full/swiftui/FocusSnapKitBundle.generated.swift",
    );
    my %accessors = map { $_ => slurp($accessor_paths{$_}) } keys %accessor_paths;
    validate_designsystem_trap($accessors{DesignSystem});
    validate_compat_accessor($accessors{Widget}, 'Focus_Widget.bundle', 'Widget');
    validate_compat_accessor($accessors{Onboarding}, 'Focus_Onboarding.bundle', 'Onboarding');
    validate_portable_accessor($accessors{Licenses}, 'Focus_Licenses.bundle', 'Licenses');
    validate_portable_accessor($accessors{SnapKit}, 'SnapKit_SnapKit.bundle', 'SnapKit');

    my $build = slurp($build_script);
    fail('direct swiftc build must not pretend to be SwiftPM')
        if $build =~ /(?:^|\s)-D\s*SWIFT_PACKAGE\b|(?:^|\s)-DSWIFT_PACKAGE\b/m;
    fail('direct swiftc build must not inject SwiftPM resource availability defines')
        if contains($build, '-D SWIFT_MODULE_RESOURCE_BUNDLE_')
            || contains($build, '-DSWIFT_MODULE_RESOURCE_BUNDLE_');
    require_all_compile_slices($build);
    for my $snippet (
        '$PROBE_APP/SnapKit_SnapKit.bundle',
        '$LICENSES_APP/Focus_Licenses.bundle',
        'resource-accessor-provenance.tsv',
    ) {
        fail("direct build lacks accessor provenance/staging '$snippet'")
            unless contains($build, $snippet);
    }
    fail('Licenses resources are still staged loose in main Contents/Resources')
        if contains($build, '$LICENSES_APP/Contents/Resources/focus-ios.plist')
            || contains($build, '$LICENSES_APP/Contents/Resources/license-list.plist');

    my @hits = upstream_conditional_hits($focus_root, $snapkit_root);
    fail('upstream resource-define conditional branches appeared: ' . join(', ', @hits))
        if @hits;

    my @rows = (
        ['format', 'focus-resource-accessor-provenance-v2'],
        ['toolchain', 'Apple-SwiftPM-6.2.1-swiftlang-6.2.1.4.8'],
        ['input', 'Focus/Package.swift', $EXPECTED_HASHES{'Focus/Package.swift'}],
        ['input', 'Focus/Package.resolved', $EXPECTED_HASHES{'Focus/Package.resolved'}],
        ['input', 'SnapKit/Package.swift', $EXPECTED_HASHES{'SnapKit/Package.swift'}],
        ['input', 'SnapKit/PrivacyInfo.xcprivacy', $EXPECTED_HASHES{'SnapKit/PrivacyInfo.xcprivacy'}],
        ['swiftpm', 'Focus/DesignSystem', 'unavailable', '-', 'SWIFT_PACKAGE,SWIFT_MODULE_RESOURCE_BUNDLE_UNAVAILABLE'],
        ['swiftpm', 'Focus/Widget', 'unavailable', '-', 'SWIFT_PACKAGE,SWIFT_MODULE_RESOURCE_BUNDLE_UNAVAILABLE'],
        ['swiftpm', 'Focus/Onboarding', 'unavailable', '-', 'SWIFT_PACKAGE,SWIFT_MODULE_RESOURCE_BUNDLE_UNAVAILABLE'],
        ['swiftpm', 'Focus/Licenses', 'available', 'Focus_Licenses.bundle', 'SWIFT_PACKAGE,SWIFT_MODULE_RESOURCE_BUNDLE_AVAILABLE'],
        ['swiftpm', 'SnapKit/SnapKit', 'available', 'SnapKit_SnapKit.bundle', 'SWIFT_PACKAGE,SWIFT_MODULE_RESOURCE_BUNDLE_AVAILABLE'],
        ['normalized-accessor', 'Focus/Licenses', $EXPECTED_HASHES{'oracle/Focus_Licenses'}],
        ['normalized-accessor', 'SnapKit/SnapKit', $EXPECTED_HASHES{'oracle/SnapKit_SnapKit'}],
        ['normalization', 'Focus/Licenses', 'absolute-build-path=<BUILD_PATH>', 'terminal=LF-appended'],
        ['normalization', 'SnapKit/SnapKit', 'absolute-build-path=<BUILD_PATH>', 'terminal=LF-appended'],
        ['port', 'Focus/DesignSystem', 'compile-only-trap', '-'],
        ['port', 'Focus/Widget', 'compatibility-repair', 'Focus_Widget.bundle'],
        ['port', 'Focus/Onboarding', 'compatibility-repair', 'Focus_Onboarding.bundle'],
        ['port', 'Focus/Licenses', 'portable-generated-primary', 'Focus_Licenses.bundle'],
        ['port', 'SnapKit/SnapKit', 'portable-generated-primary', 'SnapKit_SnapKit.bundle'],
        ['direct-swiftc', 'resource-defines', 'none', 'upstream-conditional-hits=0'],
    );
    print join("\t", @$_), "\n" for @rows;
}

sub selftest_command {
    my $valid = <<'SWIFT';
let package = Package(targets: [
  .target(name: "Widget"),
  .target(name: "Licenses", resources: [.copy("a.plist"), .copy("b.plist")])
])
SWIFT
    my $parsed = manifest_target_resources($valid);
    require_manifest_resources(
        $parsed,
        { Widget => [], Licenses => ['a.plist', 'b.plist'] },
        'fixture',
    );
    my $portable = <<'SWIFT';
Bundle.main.bundleURL.appendingPathComponent("Focus_Licenses.bundle")
Bundle(path: mainPath)
Swift.fatalError("missing")
SWIFT
    validate_portable_accessor($portable, 'Focus_Licenses.bundle', 'fixture');

    my $valid_build = join "\n", map {
        '"${SWIFTC[@]}" -parse-as-library -module-name ' . $_->[0]
            . ' /support/' . $_->[1]
    } @COMPILE_SUPPORT;
    require_all_compile_slices($valid_build);

    my @negatives = (
        sub { require_manifest_resources($parsed, { Widget => [] }, 'missing-target') },
        sub { manifest_target_resources('.target(name: "Licenses", resources: [.process("a")])') },
        sub { validate_portable_accessor("Bundle.main\n", 'Focus_Licenses.bundle', 'main-substitution') },
        sub { validate_portable_accessor($portable . "\nlet buildPath = \"/private/tmp/x\"", 'Focus_Licenses.bundle', 'absolute-fallback') },
        sub { my $wrong = $portable; $wrong =~ s/Focus_Licenses/Wrong/g; validate_portable_accessor($wrong, 'Focus_Licenses.bundle', 'wrong-name') },
        sub { validate_designsystem_trap("compatibility build support\ndeclares no DesignSystem resources\nSWIFT_MODULE_RESOURCE_BUNDLE_UNAVAILABLE\nSwift.fatalError()\nFocus_DesignSystem.bundle") },
    );
    for my $index (0 .. $#COMPILE_SUPPORT) {
        my ($module, $support) = @{$COMPILE_SUPPORT[$index]};
        my $next = ($index + 1) % @COMPILE_SUPPORT;
        my $next_support = $COMPILE_SUPPORT[$next]->[1];

        my @removed_lines = split /\n/, $valid_build;
        $removed_lines[$index] =~ s/\Q$support\E//
            or fail("selftest could not remove $support");
        my $removed = join("\n", @removed_lines)
            . "\nlater-ledger\t$support\n";
        push @negatives, sub { require_all_compile_slices($removed) };

        my @moved_lines = split /\n/, $valid_build;
        $moved_lines[$index] =~ s/\Q$support\E//
            or fail("selftest could not move $support");
        $moved_lines[$next] .= " /misplaced/$support";
        my $moved = join("\n", @moved_lines);
        push @negatives, sub { require_all_compile_slices($moved) };

        my @swapped_lines = split /\n/, $valid_build;
        $swapped_lines[$index] =~ s/\Q$support\E/__SWAPPED_SUPPORT__/
            or fail("selftest could not stage swap for $support");
        $swapped_lines[$next] =~ s/\Q$next_support\E/$support/
            or fail("selftest could not swap $next_support");
        $swapped_lines[$index] =~ s/__SWAPPED_SUPPORT__/$next_support/;
        my $swapped = join("\n", @swapped_lines);
        push @negatives, sub { require_all_compile_slices($swapped) };
    }
    my $index = 0;
    for my $negative (@negatives) {
        ++$index;
        my $passed = eval { $negative->(); 1 };
        fail("negative selftest $index unexpectedly passed") if $passed;
        fail("negative selftest $index did not fail closed")
            unless $@ =~ /^focus_resource_accessor_attest:/;
    }
    print "RESOURCE_ACCESSOR_SELFTEST_OK positives=3 negatives=21\n";
}

sub main {
    my @args = @_;
    my $command = shift @args;
    fail('usage: focus_resource_accessor_attest.pl attest|selftest [options]')
        unless defined $command;
    if ($command eq 'attest') {
        attest_command(@args);
    } elsif ($command eq 'selftest') {
        fail('selftest takes no arguments') if @args;
        selftest_command();
    } else {
        fail("unknown command: $command");
    }
    return 0;
}

exit main(@ARGV);
