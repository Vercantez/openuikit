#!/usr/bin/env perl
# Fail-closed policy and source attestation for the OpenCombine Mach-O oracle.
use strict;
use warnings;
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Basename qw(basename dirname);
use File::Find qw(find);
use File::Path qw(make_path);
use File::Spec;
use JSON::PP;

my @TOP_KEYS = qw(
    assets compiler_inputs core_sources dispatch_boundary helper_patch
    isolated_inputs link_inputs oracles repository runtime_root schema toolchain
);
my @ASSET_KEYS = (
    'Combine.swift',
    'oracles/module-shadow-probe.swift',
    'oracles/oracle-mutation.patch',
    'oracles/published_oracle.swift',
    'oracles/published_oracle_mutated.swift',
    'oracles/published_oracle_reentrant.swift',
    'patches/COpenCombineHelpers-pthread-recursive.patch',
);
my @LINK_KEYS = (
    '/work/fe/sysroot/usr/lib/libSystem.B.tbd',
    '/work/fe/sysroot/usr/lib/swift/libswift_Concurrency.tbd',
    '/work/lib/libc++abi.dylib',
    '/work/lib/libobjc.A.dylib',
    '/work/lib/libswiftCore.dylib',
    '/work/lib/libswiftcompat.dylib',
);
my @COMPILER_INPUT_KEYS = (
    'Sources/COpenCombineHelpers/COpenCombineHelpers.cpp',
    'Sources/COpenCombineHelpers/include/COpenCombineHelpers.h',
    'Sources/COpenCombineHelpers/include/module.modulemap',
    'Sources/OpenCombineDispatch/DispatchQueue+Scheduler.swift',
);
my @COMPILER_INPUT_ROOTS = (
    'Sources/COpenCombineHelpers',
    'Sources/OpenCombineDispatch',
);
my @DISPATCH_BUNDLE_KEYS = (
    'arm64e-apple-ios-macabi.swiftdoc',
    'arm64e-apple-ios-macabi.swiftinterface',
    'arm64e-apple-macos.swiftdoc',
    'arm64e-apple-macos.swiftinterface',
    'x86_64-apple-ios-macabi.swiftdoc',
    'x86_64-apple-ios-macabi.swiftinterface',
    'x86_64-apple-macos.swiftdoc',
    'x86_64-apple-macos.swiftinterface',
);
my @RUNTIME_KEYS = (
    '.manifest',
    '.umbrellas',
    'darwin/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation',
    'darwin/System/Library/Frameworks/Foundation.framework/Foundation',
    'darwin/usr/lib/libSystem.B.dylib',
    'darwin/usr/lib/libSystem.B.lowheap.dylib',
    'darwin/usr/lib/libSystem.real.dylib',
    'darwin/usr/lib/libc++.1.dylib',
    'darwin/usr/lib/libc++.real.dylib',
    'darwin/usr/lib/libc++abi.dylib',
    'darwin/usr/lib/libobjc.A.dylib',
    'darwin/usr/lib/libquartz.dylib',
    'darwin/usr/lib/libswiftcompat.dylib',
    'darwin/usr/lib/swift/libswiftCore.dylib',
    'darwin/usr/lib/swift/libswiftObjectiveC.dylib',
    'darwin/usr/lib/swift/libswift_Concurrency.dylib',
    'machorun',
);

sub refuse { die "$_[0]\n" }

sub bytes {
    my ($path) = @_;
    open my $fh, '<:raw', $path or refuse("cannot read $path: $!");
    local $/;
    my $value = <$fh>;
    close $fh or refuse("cannot close $path: $!");
    return defined($value) ? $value : '';
}

sub sha_file { return sha256_hex(bytes($_[0])) }

sub assert_hash {
    my ($value, $where) = @_;
    refuse("$where must be a lowercase SHA-256")
        unless defined($value) && !ref($value) && $value =~ /\A[0-9a-f]{64}\z/;
}

sub assert_keys {
    my ($object, $expected, $where) = @_;
    refuse("$where must be an object") unless ref($object) eq 'HASH';
    my @actual = sort keys %$object;
    my @wanted = sort @$expected;
    refuse("$where keys changed: expected [" . join(', ', @wanted) .
           "], got [" . join(', ', @actual) . "]")
        unless join("\0", @actual) eq join("\0", @wanted);
}

sub assert_safe_relative {
    my ($value, $where) = @_;
    refuse("$where must be a nonempty relative path")
        unless defined($value) && !ref($value) && length($value) &&
               !File::Spec->file_name_is_absolute($value);
    refuse("$where contains an unsafe path component")
        if grep { $_ eq '' || $_ eq '.' || $_ eq '..' }
                File::Spec->splitdir($value);
    refuse("$where contains a control character") if $value =~ /[\x00-\x1f\x7f]/;
}

sub load_policy {
    my ($path) = @_;
    my $policy = eval { JSON::PP->new->utf8->decode(bytes($path)) };
    refuse("cannot parse policy $path: $@") if $@;
    assert_keys($policy, \@TOP_KEYS, 'policy');
    refuse('policy schema must remain exactly 1') unless $policy->{schema} == 1;

    assert_keys($policy->{repository}, [qw(commit url)], 'repository');
    refuse('repository URL changed')
        unless $policy->{repository}{url} eq
               'https://github.com/OpenCombine/OpenCombine.git';
    refuse('repository commit must be a full hexadecimal object ID')
        unless $policy->{repository}{commit} =~ /\A[0-9a-f]{40}\z/;

    assert_keys($policy->{core_sources}, [qw(root sha256 swift_file_count)],
                'core_sources');
    refuse("core source root must remain exactly 'Sources/OpenCombine'")
        unless $policy->{core_sources}{root} eq 'Sources/OpenCombine';
    refuse('core source denominator must remain exactly 103')
        unless $policy->{core_sources}{swift_file_count} =~ /\A103\z/;
    assert_hash($policy->{core_sources}{sha256}, 'core_sources.sha256');

    assert_keys($policy->{compiler_inputs}, [qw(files roots)],
                'compiler_inputs');
    assert_keys($policy->{compiler_inputs}{files}, \@COMPILER_INPUT_KEYS,
                'compiler_inputs.files');
    assert_hash($policy->{compiler_inputs}{files}{$_},
                "compiler_inputs.files.$_") for @COMPILER_INPUT_KEYS;
    refuse('compiler input roots must remain the exact two reviewed roots')
        unless ref($policy->{compiler_inputs}{roots}) eq 'ARRAY' &&
               join("\0", @{$policy->{compiler_inputs}{roots}}) eq
               join("\0", @COMPILER_INPUT_ROOTS);

    assert_keys($policy->{helper_patch},
        [qw(path patch_asset patch_sha256 patched_object_sha256 patched_sha256 upstream_sha256)],
        'helper_patch');
    refuse('helper path scope changed')
        unless $policy->{helper_patch}{path} eq
               'Sources/COpenCombineHelpers/COpenCombineHelpers.cpp';
    refuse('helper patch asset scope changed')
        unless $policy->{helper_patch}{patch_asset} eq
               'patches/COpenCombineHelpers-pthread-recursive.patch';
    assert_hash($policy->{helper_patch}{upstream_sha256},
                'helper_patch.upstream_sha256');
    assert_hash($policy->{helper_patch}{patch_sha256},
                'helper_patch.patch_sha256');
    assert_hash($policy->{helper_patch}{patched_sha256},
                'helper_patch.patched_sha256');
    assert_hash($policy->{helper_patch}{patched_object_sha256},
                'helper_patch.patched_object_sha256');

    assert_keys($policy->{assets}, \@ASSET_KEYS, 'assets');
    assert_hash($policy->{assets}{$_}, "assets.$_") for @ASSET_KEYS;
    refuse('helper patch hash disagrees with asset hash')
        unless $policy->{helper_patch}{patch_sha256} eq
               $policy->{assets}{$policy->{helper_patch}{patch_asset}};
    refuse('helper upstream hash disagrees with compiler input hash')
        unless $policy->{helper_patch}{upstream_sha256} eq
               $policy->{compiler_inputs}{files}{$policy->{helper_patch}{path}};

    assert_keys($policy->{link_inputs}, \@LINK_KEYS, 'link_inputs');
    assert_hash($policy->{link_inputs}{$_}, "link_inputs.$_") for @LINK_KEYS;

    assert_keys($policy->{isolated_inputs},
                [qw(concurrency_module sdk swift_module)], 'isolated_inputs');
    for my $name (qw(swift_module concurrency_module)) {
        my $input = $policy->{isolated_inputs}{$name};
        assert_keys($input,
                    [qw(bundle_relative directory_count file_count sha256 symlink_count)],
                    "isolated_inputs.$name");
        assert_safe_relative($input->{bundle_relative},
                             "isolated_inputs.$name.bundle_relative");
        my $expected = $name eq 'swift_module'
            ? 'Swift.swiftmodule' : '_Concurrency.swiftmodule';
        refuse("isolated $name bundle scope changed")
            unless $input->{bundle_relative} eq $expected;
        refuse("isolated $name directory denominator changed")
            unless $input->{directory_count} =~ /\A0\z/;
        refuse("isolated $name file denominator changed")
            unless $input->{file_count} =~ /\A6\z/;
        refuse("isolated $name symlink denominator changed")
            unless $input->{symlink_count} =~ /\A0\z/;
        assert_hash($input->{sha256}, "isolated_inputs.$name.sha256");
    }
    my $sdk_input = $policy->{isolated_inputs}{sdk};
    assert_keys($sdk_input,
                [qw(directory_count file_count sha256 source_path symlink_count)],
                'isolated_inputs.sdk');
    refuse('isolated SDK source path scope changed')
        unless $sdk_input->{source_path} eq '/work/sdk/MacOSX.sdk';
    refuse('isolated SDK directory denominator changed')
        unless $sdk_input->{directory_count} =~ /\A95\z/;
    refuse('isolated SDK file denominator changed')
        unless $sdk_input->{file_count} =~ /\A1559\z/;
    refuse('isolated SDK symlink denominator changed')
        unless $sdk_input->{symlink_count} =~ /\A3\z/;
    assert_hash($sdk_input->{sha256}, 'isolated_inputs.sdk.sha256');

    assert_keys($policy->{runtime_root}, [qw(files required_libsystem_export)],
                'runtime_root');
    assert_keys($policy->{runtime_root}{files}, \@RUNTIME_KEYS,
                'runtime_root.files');
    assert_hash($policy->{runtime_root}{files}{$_}, "runtime_root.files.$_")
        for @RUNTIME_KEYS;
    refuse('runtime discriminator changed')
        unless $policy->{runtime_root}{required_libsystem_export} eq
               '__NSGetMachExecuteHeader';
    my %link_runtime_pairs = (
        '/work/lib/libc++abi.dylib' => 'darwin/usr/lib/libc++abi.dylib',
        '/work/lib/libobjc.A.dylib' => 'darwin/usr/lib/libobjc.A.dylib',
        '/work/lib/libswiftCore.dylib' => 'darwin/usr/lib/swift/libswiftCore.dylib',
        '/work/lib/libswiftcompat.dylib' => 'darwin/usr/lib/libswiftcompat.dylib',
    );
    for my $link (sort keys %link_runtime_pairs) {
        my $runtime = $link_runtime_pairs{$link};
        refuse("link/runtime hash agreement changed for $link and $runtime")
            unless $policy->{link_inputs}{$link} eq
                   $policy->{runtime_root}{files}{$runtime};
    }

    assert_keys($policy->{toolchain}, [qw(
        clang_version clangxx_sha256 concurrency_module_relative
        concurrency_module_sha256 container_image_id lld_sha256 lld_version
        machorun_sha256 nm_sha256 objdump_sha256 sdk_path swift_module_relative
        swift_module_sha256 swift_version swiftc_sha256 target
    )], 'toolchain');
    assert_hash($policy->{toolchain}{clangxx_sha256},
                'toolchain.clangxx_sha256');
    assert_hash($policy->{toolchain}{concurrency_module_sha256},
                'toolchain.concurrency_module_sha256');
    assert_hash($policy->{toolchain}{machorun_sha256},
                'toolchain.machorun_sha256');
    assert_hash($policy->{toolchain}{swift_module_sha256},
                'toolchain.swift_module_sha256');
    assert_hash($policy->{toolchain}{lld_sha256}, 'toolchain.lld_sha256');
    assert_hash($policy->{toolchain}{nm_sha256}, 'toolchain.nm_sha256');
    assert_hash($policy->{toolchain}{objdump_sha256}, 'toolchain.objdump_sha256');
    assert_hash($policy->{toolchain}{swiftc_sha256}, 'toolchain.swiftc_sha256');
    refuse('container image ID must be a sha256 image ID')
        unless $policy->{toolchain}{container_image_id} =~ /\Asha256:[0-9a-f]{64}\z/;
    refuse('target scope changed')
        unless $policy->{toolchain}{target} eq 'arm64-apple-macos13.0';
    refuse('SDK path scope changed')
        unless $policy->{toolchain}{sdk_path} eq '/work/sdk/MacOSX.sdk';
    refuse('SDK path disagrees with isolated input policy')
        unless $policy->{toolchain}{sdk_path} eq
               $policy->{isolated_inputs}{sdk}{source_path};
    assert_safe_relative($policy->{toolchain}{swift_module_relative},
                         'toolchain.swift_module_relative');
    assert_safe_relative($policy->{toolchain}{concurrency_module_relative},
                         'toolchain.concurrency_module_relative');
    refuse('Swift module-relative scope changed')
        unless $policy->{toolchain}{swift_module_relative} eq
               'Swift.swiftmodule/arm64-apple-macos.swiftmodule';
    refuse('Concurrency module-relative scope changed')
        unless $policy->{toolchain}{concurrency_module_relative} eq
               '_Concurrency.swiftmodule/arm64-apple-macos.swiftmodule';

    assert_keys($policy->{oracles}, [qw(
        missing_dylib_exit missing_dylib_line missing_dylib_stream
        mutated_exit mutated_line mutated_stream positive_exit positive_line
        positive_stream reentrant_exit reentrant_line reentrant_stream
    )], 'oracles');
    my %oracle_contract = (
        missing_dylib_exit => 72,
        missing_dylib_line =>
            q{machorun: cannot find dylib '/usr/lib/swift/libOpenCombine.dylib'},
        missing_dylib_stream => 'stderr',
        mutated_exit => 133,
        mutated_line => 'PublishedOracle_mutated/published_oracle.generated.swift:26: Fatal error: ORACLE_FAIL received=[3, 5, 9] stored=[3, 3, 5]',
        mutated_stream => 'stderr',
        positive_exit => 0,
        positive_line => 'ORACLE_OK received=3,5,8 stored=3,3,5',
        positive_stream => 'stdout',
        reentrant_exit => 0,
        reentrant_line => 'REENTRANT_OK received=3,5,8 stored=3,3,3 final=5',
        reentrant_stream => 'stdout',
    );
    for my $key (sort keys %oracle_contract) {
        refuse("oracle contract changed for $key")
            unless "$policy->{oracles}{$key}" eq "$oracle_contract{$key}";
    }
    assert_keys($policy->{dispatch_boundary}, [qw(
        dispatch_swiftmodule_bundle_files dispatch_swiftmodule_bundle_path
        dispatch_swiftmodule_entry_kind
        expected_failure_exit expected_interface_error_count
        expected_interface_error_line expected_source_error_count
        expected_source_error_line
        expected_dispatch_swiftmodule_bundle_count
        expected_dispatch_swiftmodule_bundle_directory_count
        expected_libswift_dispatch_dylib_count
        expected_target_compatible_module_count libdispatch_path
        libdispatch_sha256 libswift_dispatch_tbd_path
        libswift_dispatch_tbd_sha256 target_compatible_module_stem
    )], 'dispatch_boundary');
    assert_keys($policy->{dispatch_boundary}{dispatch_swiftmodule_bundle_files},
                \@DISPATCH_BUNDLE_KEYS,
                'dispatch_boundary.dispatch_swiftmodule_bundle_files');
    assert_hash(
        $policy->{dispatch_boundary}{dispatch_swiftmodule_bundle_files}{$_},
        "dispatch_boundary.dispatch_swiftmodule_bundle_files.$_"
    ) for @DISPATCH_BUNDLE_KEYS;
    assert_hash($policy->{dispatch_boundary}{libdispatch_sha256},
                'dispatch_boundary.libdispatch_sha256');
    assert_hash($policy->{dispatch_boundary}{libswift_dispatch_tbd_sha256},
                'dispatch_boundary.libswift_dispatch_tbd_sha256');
    refuse('Dispatch.swiftmodule bundle path changed')
        unless $policy->{dispatch_boundary}{dispatch_swiftmodule_bundle_path} eq
               '/work/fe/sysroot/usr/lib/swift/Dispatch.swiftmodule';
    refuse('Dispatch.swiftmodule expected entry kind changed')
        unless $policy->{dispatch_boundary}{dispatch_swiftmodule_entry_kind} eq
               'directory';
    refuse('Dispatch.swiftmodule bundle denominator must remain exactly one')
        unless $policy->{dispatch_boundary}{expected_dispatch_swiftmodule_bundle_count} =~ /\A1\z/;
    refuse('Dispatch.swiftmodule bundle directory denominator must remain zero')
        unless $policy->{dispatch_boundary}{expected_dispatch_swiftmodule_bundle_directory_count} =~ /\A0\z/;
    refuse('target-compatible Dispatch module stem changed')
        unless $policy->{dispatch_boundary}{target_compatible_module_stem} eq
               'arm64-apple-macos';
    refuse('target-compatible Dispatch module/interface denominator must remain zero')
        unless $policy->{dispatch_boundary}{expected_target_compatible_module_count} =~ /\A0\z/;
    refuse('libswiftDispatch.dylib absence denominator must remain exactly zero')
        unless $policy->{dispatch_boundary}{expected_libswift_dispatch_dylib_count} =~ /\A0\z/;
    refuse('OpenCombineDispatch failure exit changed')
        unless $policy->{dispatch_boundary}{expected_failure_exit} =~ /\A1\z/;
    refuse('OpenCombineDispatch interface-error denominator changed')
        unless $policy->{dispatch_boundary}{expected_interface_error_count} =~ /\A2\z/;
    refuse('OpenCombineDispatch source-error denominator changed')
        unless $policy->{dispatch_boundary}{expected_source_error_count} =~ /\A1\z/;
    my $dispatch_interface_error =
        q{<SUBJECT>/work/inputs/dispatch-work/fe/sysroot/usr/lib/swift/Dispatch.swiftmodule/arm64e-apple-macos.swiftinterface:9:8: error: no such module '_StringProcessing'};
    my $dispatch_source_error =
        q{<SUBJECT>/source/Sources/OpenCombineDispatch/DispatchQueue+Scheduler.swift:8:8: error: failed to build module 'Dispatch'; this SDK is not supported by the compiler (the SDK is built with 'Apple Swift version 6.2.1 effective-5.10 (swiftlang-6.2.1.4.7 clang-1700.4.4.1)', while this compiler is 'Swift version 6.2.4 (swift-6.2.4-RELEASE)'). Please select a toolchain which matches the SDK.};
    refuse('OpenCombineDispatch interface-error discriminator changed')
        unless $policy->{dispatch_boundary}{expected_interface_error_line} eq
               $dispatch_interface_error;
    refuse('OpenCombineDispatch source-error discriminator changed')
        unless $policy->{dispatch_boundary}{expected_source_error_line} eq
               $dispatch_source_error;
    refuse('libdispatch path scope changed')
        unless $policy->{dispatch_boundary}{libdispatch_path} eq
               '/work/lib/libdispatch.dylib';
    refuse('libswiftDispatch tbd path scope changed')
        unless $policy->{dispatch_boundary}{libswift_dispatch_tbd_path} eq
               '/work/fe/sysroot/usr/lib/swift/libswiftDispatch.tbd';
    return $policy;
}

sub git_bytes {
    my ($repo, @args) = @_;
    # docker cp preserves the host UID, which is intentionally not root inside
    # fm-build. Trust only this already-resolved checkout for this one command;
    # never mutate global Git configuration or broaden safe.directory.
    open my $fh, '-|', 'git', '-c', "safe.directory=$repo", '-C', $repo, @args
        or refuse("cannot run git @args: $!");
    binmode $fh;
    local $/;
    my $value = <$fh>;
    my $ok = close $fh;
    refuse("git @args failed") unless $ok;
    return defined($value) ? $value : '';
}

sub digest_sources {
    my ($repo, $paths) = @_;
    my $digest = Digest::SHA->new(256);
    for my $rel (@$paths) {
        $digest->add($rel, "\0", bytes("$repo/$rel"), "\0");
    }
    return $digest->hexdigest;
}

sub verify_assets {
    my ($policy, $tool_root) = @_;
    for my $rel (@ASSET_KEYS) {
        my $path = "$tool_root/$rel";
        refuse("asset is absent: $rel") unless -e $path;
        refuse("asset must be a regular non-symlink file: $rel")
            unless -f $path && !-l $path;
        my $actual = sha_file($path);
        refuse("asset hash changed for $rel: expected " .
               "$policy->{assets}{$rel}, got $actual")
            unless $actual eq $policy->{assets}{$rel};
    }
}

sub attest_sources {
    my ($policy, $policy_path, $repo_arg, $list_path, $audit_path) = @_;
    my $repo = abs_path($repo_arg);
    refuse("repository is not a directory: $repo_arg")
        unless defined($repo) && -d $repo;
    my $tool_root = abs_path(dirname($policy_path));
    refuse("cannot resolve policy directory for $policy_path")
        unless defined($tool_root) && -d $tool_root;
    verify_assets($policy, $tool_root);

    my $head = git_bytes($repo, qw(rev-parse HEAD));
    $head =~ s/\s+\z//;
    refuse("OpenCombine pin changed: expected $policy->{repository}{commit}, got $head")
        unless $head eq $policy->{repository}{commit};

    my $root = $policy->{core_sources}{root};
    my $helper = $policy->{helper_patch}{path};
    my $dirty = git_bytes($repo, 'status', '--porcelain=v1',
                          '--untracked-files=all', '--', $root,
                          @COMPILER_INPUT_ROOTS);
    refuse("OpenCombine compiler subject is not clean:\n$dirty") if length $dirty;

    my @tracked = sort grep { length($_) && /[.]swift\z/ }
                  split /\0/, git_bytes($repo, 'ls-files', '-z', '--', $root);
    my @disk;
    my $disk_root = "$repo/$root";
    refuse("core source root is absent: $disk_root") unless -d $disk_root;
    find({
        no_chdir => 1,
        wanted => sub {
            return unless /[.]swift\z/;
            my $path = $File::Find::name;
            refuse("Swift source must not be a symlink: $path") if -l $path;
            refuse("Swift source must be a regular file: $path") unless -f $path;
            my $rel = File::Spec->abs2rel($path, $repo);
            $rel =~ s{\\}{/}g;
            refuse("newline in source path is unsupported") if $rel =~ /[\r\n]/;
            push @disk, $rel;
        },
    }, $disk_root);
    @disk = sort @disk;
    refuse('tracked/disk Swift source inventories differ')
        unless join("\0", @tracked) eq join("\0", @disk);
    refuse("source denominator changed: expected " .
           "$policy->{core_sources}{swift_file_count}, got " . scalar(@tracked))
        unless @tracked == $policy->{core_sources}{swift_file_count};

    my @compiler_tracked = sort grep { length($_) }
        split /\0/, git_bytes($repo, 'ls-files', '-z', '--',
                              @COMPILER_INPUT_ROOTS);
    refuse('tracked compiler-input inventory changed')
        unless join("\0", @compiler_tracked) eq
               join("\0", sort @COMPILER_INPUT_KEYS);
    my @compiler_disk;
    for my $compiler_root (@COMPILER_INPUT_ROOTS) {
        my $path = "$repo/$compiler_root";
        refuse("compiler input root is absent: $path") unless -d $path;
        find({
            no_chdir => 1,
            wanted => sub {
                my $entry = $File::Find::name;
                refuse("compiler input contains a symlink: $entry") if -l $entry;
                return if -d $entry;
                refuse("compiler input contains a non-regular file: $entry")
                    unless -f $entry;
                my $rel = File::Spec->abs2rel($entry, $repo);
                $rel =~ s{\\}{/}g;
                refuse('newline in compiler-input path is unsupported')
                    if $rel =~ /[\r\n]/;
                push @compiler_disk, $rel;
            },
        }, $path);
    }
    @compiler_disk = sort @compiler_disk;
    refuse('tracked/disk compiler-input inventories differ')
        unless join("\0", @compiler_tracked) eq join("\0", @compiler_disk);
    my @compiler_inputs;
    for my $rel (@COMPILER_INPUT_KEYS) {
        my $got = sha_file("$repo/$rel");
        my $want = $policy->{compiler_inputs}{files}{$rel};
        refuse("compiler input hash changed for $rel: expected $want, got $got")
            unless $got eq $want;
        push @compiler_inputs, +{ path => $rel, sha256 => $got };
    }

    my $digest = digest_sources($repo, \@tracked);
    refuse("core source digest changed: expected $policy->{core_sources}{sha256}, " .
           "got $digest") unless $digest eq $policy->{core_sources}{sha256};
    my $helper_hash = sha_file("$repo/$helper");
    refuse("upstream helper hash changed: expected " .
           "$policy->{helper_patch}{upstream_sha256}, got $helper_hash")
        unless $helper_hash eq $policy->{helper_patch}{upstream_sha256};

    for my $path ($list_path, $audit_path) {
        my ($volume, $dirs) = File::Spec->splitpath($path);
        make_path(File::Spec->catpath($volume, $dirs, '')) if length $dirs;
    }
    open my $list, '>:raw', $list_path or refuse("cannot write $list_path: $!");
    print {$list} join("\0", map { "$repo/$_" } @tracked), "\0";
    close $list or refuse("cannot close $list_path: $!");

    my @sources = map {
        +{ path => $_, sha256 => sha_file("$repo/$_") }
    } @tracked;
    my $audit = {
        schema => 1,
        repository => $repo,
        repository_commit => $head,
        source_root => $root,
        swift_source_count => scalar(@tracked),
        swift_source_digest => $digest,
        helper_path => $helper,
        helper_upstream_sha256 => $helper_hash,
        compiler_inputs => \@compiler_inputs,
        sources => \@sources,
    };
    open my $out, '>:raw', $audit_path or refuse("cannot write $audit_path: $!");
    print {$out} JSON::PP->new->canonical->pretty->encode($audit);
    close $out or refuse("cannot close $audit_path: $!");
    print "OpenCombine commit: $head\n";
    print "source denominator: " . scalar(@tracked) . " Swift files\n";
    print "source digest: $digest\n";
    print "helper upstream sha256: $helper_hash\n";
    print "additional compiler inputs: " . scalar(@compiler_inputs) .
          " exact files\n";
    print "NUL source list: $list_path\n";
}

sub audit_runtime {
    my ($policy, $root_arg) = @_;
    my $root = abs_path($root_arg);
    refuse("runtime root is not a directory: $root_arg")
        unless defined($root) && -d $root;
    my @disk;
    find({
        no_chdir => 1,
        wanted => sub {
            refuse("runtime root contains a symlink: $File::Find::name")
                if -l $File::Find::name;
            return if -d $File::Find::name;
            refuse("runtime root contains a non-regular file: $File::Find::name")
                unless -f $File::Find::name;
            my $rel = File::Spec->abs2rel($File::Find::name, $root);
            $rel =~ s{\\}{/}g;
            push @disk, $rel;
        },
    }, $root);
    @disk = sort @disk;
    refuse('runtime-root file inventory changed')
        unless join("\0", @disk) eq join("\0", sort @RUNTIME_KEYS);
    for my $rel (@RUNTIME_KEYS) {
        my $got = sha_file("$root/$rel");
        my $want = $policy->{runtime_root}{files}{$rel};
        refuse("runtime-root hash changed for $rel: expected $want, got $got")
            unless $got eq $want;
    }
    print "runtime root: exact " . scalar(@RUNTIME_KEYS) . "-file subject\n";
}

sub attest_input_tree {
    my ($policy, $name, $root_arg, $manifest_path, $audit_path) = @_;
    refuse("unknown isolated input: $name")
        unless $name eq 'sdk' || $name eq 'swift_module' ||
               $name eq 'concurrency_module';
    my $root = abs_path($root_arg);
    refuse("isolated-input root is not a directory: $root_arg")
        unless defined($root) && -d $root && !-l $root_arg;
    my @entries;
    find({
        no_chdir => 1,
        wanted => sub {
            my $path = $File::Find::name;
            return if $path eq $root;
            my $rel = File::Spec->abs2rel($path, $root);
            $rel =~ s{\\}{/}g;
            refuse("isolated-input path contains NUL: $path") if $rel =~ /\0/;
            my ($kind, $value);
            if (-l $path) {
                $kind = 'L';
                $value = readlink($path);
                refuse("cannot read isolated-input symlink: $path")
                    unless defined $value;
                refuse("isolated-input symlink target contains NUL: $path")
                    if $value =~ /\0/;
            } elsif (-d $path) {
                $kind = 'D';
                $value = '';
            } elsif (-f $path) {
                $kind = 'F';
                $value = sha_file($path);
            } else {
                refuse("isolated-input tree contains a non-regular entry: $path");
            }
            push @entries, [$rel, $kind, $value];
        },
    }, $root);
    @entries = sort { $a->[0] cmp $b->[0] } @entries;
    my %count = (D => 0, F => 0, L => 0);
    my $digest = Digest::SHA->new(256);
    for my $entry (@entries) {
        my ($rel, $kind, $value) = @$entry;
        $count{$kind}++;
        $digest->add($kind, "\0", $rel, "\0", $value, "\0");
    }
    my $got = $digest->hexdigest;
    my $expected = $policy->{isolated_inputs}{$name};
    refuse("$name directory denominator changed: expected " .
           "$expected->{directory_count}, got $count{D}")
        unless $count{D} == $expected->{directory_count};
    refuse("$name file denominator changed: expected " .
           "$expected->{file_count}, got $count{F}")
        unless $count{F} == $expected->{file_count};
    refuse("$name symlink denominator changed: expected " .
           "$expected->{symlink_count}, got $count{L}")
        unless $count{L} == $expected->{symlink_count};
    refuse("$name tree digest changed: expected $expected->{sha256}, got $got")
        unless $got eq $expected->{sha256};

    for my $path ($manifest_path, $audit_path) {
        my ($volume, $dirs) = File::Spec->splitpath($path);
        make_path(File::Spec->catpath($volume, $dirs, '')) if length $dirs;
    }
    open my $manifest, '>:raw', $manifest_path
        or refuse("cannot write $manifest_path: $!");
    for my $entry (@entries) {
        print {$manifest} join("\0", $entry->[1], $entry->[0], $entry->[2]), "\0";
    }
    close $manifest or refuse("cannot close $manifest_path: $!");
    my @audit_entries = map {
        +{ kind => $_->[1], path => $_->[0], value => $_->[2] }
    } @entries;
    my $audit = {
        schema => 1,
        input => $name,
        root => $root,
        directory_count => $count{D},
        file_count => $count{F},
        symlink_count => $count{L},
        sha256 => $got,
        entries => \@audit_entries,
    };
    open my $out, '>:raw', $audit_path or refuse("cannot write $audit_path: $!");
    print {$out} JSON::PP->new->canonical->pretty->encode($audit);
    close $out or refuse("cannot close $audit_path: $!");
    print "$name input tree: exact D=$count{D} F=$count{F} L=$count{L} sha256=$got\n";
}

sub normalized_work_path {
    my ($work_root, $path) = @_;
    my $rel = File::Spec->abs2rel($path, $work_root);
    $rel =~ s{\\}{/}g;
    refuse("path escaped audited /work root: $path")
        if $rel eq '..' || $rel =~ m{\A[.][.]/};
    return $rel eq '.' ? '/work' : "/work/$rel";
}

sub audit_dispatch {
    my ($policy, $work_arg, $audit_path) = @_;
    my $work = abs_path($work_arg);
    refuse("Dispatch audit root is not a directory: $work_arg")
        unless defined($work) && -d $work;
    my @entries;
    my @swift_dylibs;
    find({
        no_chdir => 1,
        wanted => sub {
            my $path = $File::Find::name;
            my $name = basename($path);
            if ($name eq 'Dispatch.swiftmodule') {
                my $kind = -l $path ? 'symlink' :
                           -d $path ? 'directory' :
                           -f $path ? 'regular' : 'other';
                push @entries, +{
                    path => normalized_work_path($work, $path),
                    kind => $kind,
                };
            }
            if ($name eq 'libswiftDispatch.dylib') {
                refuse("Dispatch inventory entry must be a regular non-symlink file: $path")
                    unless -f $path && !-l $path;
                push @swift_dylibs, normalized_work_path($work, $path);
            }
        },
    }, $work);
    @entries = sort { $a->{path} cmp $b->{path} } @entries;
    @swift_dylibs = sort @swift_dylibs;
    my $d = $policy->{dispatch_boundary};
    refuse('Dispatch.swiftmodule bundle count changed: expected ' .
           "$d->{expected_dispatch_swiftmodule_bundle_count}, got " .
           scalar(@entries))
        unless @entries == $d->{expected_dispatch_swiftmodule_bundle_count};
    refuse('Dispatch.swiftmodule entry path inventory changed')
        unless $entries[0]{path} eq $d->{dispatch_swiftmodule_bundle_path};
    refuse('Dispatch.swiftmodule entry kind changed: expected ' .
           "$d->{dispatch_swiftmodule_entry_kind}, got $entries[0]{kind}")
        unless $entries[0]{kind} eq $d->{dispatch_swiftmodule_entry_kind};
    refuse('libswiftDispatch.dylib count changed: expected ' .
           "$d->{expected_libswift_dispatch_dylib_count}, got " .
           scalar(@swift_dylibs))
        unless @swift_dylibs == $d->{expected_libswift_dispatch_dylib_count};

    my $bundle_rel = $d->{dispatch_swiftmodule_bundle_path};
    refuse('Dispatch bundle policy path is not beneath /work')
        unless $bundle_rel =~ s{\A/work/}{};
    my $bundle = "$work/$bundle_rel";
    my @bundle_disk;
    my @bundle_directories;
    find({
        no_chdir => 1,
        wanted => sub {
            my $path = $File::Find::name;
            refuse("Dispatch bundle contains a symlink: $path") if -l $path;
            if (-d $path) {
                my $rel = File::Spec->abs2rel($path, $bundle);
                $rel =~ s{\\}{/}g;
                push @bundle_directories, $rel unless $rel eq '.';
                return;
            }
            refuse("Dispatch bundle contains a non-regular file: $path")
                unless -f $path;
            my $rel = File::Spec->abs2rel($path, $bundle);
            $rel =~ s{\\}{/}g;
            refuse('newline in Dispatch bundle path is unsupported')
                if $rel =~ /[\r\n]/;
            push @bundle_disk, $rel;
        },
    }, $bundle);
    @bundle_disk = sort @bundle_disk;
    @bundle_directories = sort @bundle_directories;
    my $stem = $d->{target_compatible_module_stem};
    my @target_compatible = grep {
        $_ eq "$stem.swiftmodule" || $_ eq "$stem.swiftinterface"
    } @bundle_disk;
    refuse('target-compatible Dispatch module/interface count changed: expected ' .
           "$d->{expected_target_compatible_module_count}, got " .
           scalar(@target_compatible))
        unless @target_compatible == $d->{expected_target_compatible_module_count};
    refuse('Dispatch.swiftmodule bundle file inventory changed')
        unless join("\0", @bundle_disk) eq
               join("\0", sort @DISPATCH_BUNDLE_KEYS);
    refuse('Dispatch.swiftmodule bundle directory count changed: expected ' .
           "$d->{expected_dispatch_swiftmodule_bundle_directory_count}, got " .
           scalar(@bundle_directories))
        unless @bundle_directories ==
               $d->{expected_dispatch_swiftmodule_bundle_directory_count};
    my @bundle_files;
    for my $rel (@DISPATCH_BUNDLE_KEYS) {
        my $got = sha_file("$bundle/$rel");
        my $want = $d->{dispatch_swiftmodule_bundle_files}{$rel};
        refuse("Dispatch bundle hash changed for $rel: expected $want, got $got")
            unless $got eq $want;
        push @bundle_files, +{ path => $rel, sha256 => $got };
    }
    my ($volume, $dirs) = File::Spec->splitpath($audit_path);
    make_path(File::Spec->catpath($volume, $dirs, '')) if length $dirs;
    my $audit = {
        schema => 1,
        logical_work_root => '/work',
        dispatch_swiftmodule_entries => \@entries,
        bundle_directories => \@bundle_directories,
        bundle_files => \@bundle_files,
        target_compatible_module_stem => $stem,
        target_compatible_modules_or_interfaces => \@target_compatible,
        libswift_dispatch_dylibs => \@swift_dylibs,
    };
    open my $out, '>:raw', $audit_path or refuse("cannot write $audit_path: $!");
    print {$out} JSON::PP->new->canonical->pretty->encode($audit);
    close $out or refuse("cannot close $audit_path: $!");
    print "Dispatch.swiftmodule entries: " . scalar(@entries) .
          " exact directory\n";
    print "Dispatch bundle files: " . scalar(@bundle_files) .
          " exact arm64e/x86_64 files\n";
    print "Dispatch bundle nested directories: " .
          scalar(@bundle_directories) . "\n";
    print "target-compatible $stem module/interfaces: " .
          scalar(@target_compatible) . "\n";
    print "libswiftDispatch.dylib files: " . scalar(@swift_dylibs) . "\n";
}

sub parse_objdump_loads {
    my ($path) = @_;
    my $input = bytes($path);
    refuse("Mach-O load audit contains NUL: $path") if $input =~ /\0/;
    $input =~ s/\r\n/\n/g;
    my @lines = split /\n/, $input, -1;
    pop @lines if @lines && $lines[-1] eq '';
    refuse("Mach-O load audit is empty: $path") unless @lines;
    my %allowed = map { $_ => 1 } qw(
        LC_ID_DYLIB LC_LOAD_DYLIB LC_LOAD_WEAK_DYLIB LC_REEXPORT_DYLIB
        LC_LOAD_UPWARD_DYLIB LC_LAZY_LOAD_DYLIB
    );
    my @loads;
    for (my $i = 0; $i < @lines; $i++) {
        next unless $lines[$i] =~ /\A\s*cmd\s+(LC_[A-Z0-9_]*DYLIB)\s*\z/;
        my $kind = $1;
        refuse("unsupported Mach-O dylib load kind: $kind") unless $allowed{$kind};
        my ($name, $current, $compatibility);
        for (my $j = $i + 1; $j < @lines; $j++) {
            last if $lines[$j] =~ /\ALoad command \d+\s*\z/;
            if ($lines[$j] =~ /\A\s*name\s+(.+?)\s+\(offset\s+\d+\)\s*\z/) {
                refuse("duplicate name in $kind block") if defined $name;
                $name = $1;
            } elsif ($lines[$j] =~ /\A\s*current version\s+(\d+[.]\d+[.]\d+)\s*\z/) {
                refuse("duplicate current version in $kind block") if defined $current;
                $current = $1;
            } elsif ($lines[$j] =~ /\A\s*compatibility version\s+(\d+[.]\d+[.]\d+)\s*\z/) {
                refuse("duplicate compatibility version in $kind block")
                    if defined $compatibility;
                $compatibility = $1;
            }
        }
        refuse("incomplete Mach-O dylib load block for $kind")
            unless defined($name) && defined($current) && defined($compatibility);
        refuse("unsafe empty/control Mach-O load spelling")
            if !length($name) || $name =~ /[\x00-\x1f\x7f]/;
        push @loads, join("\t", $kind, $name, $compatibility, $current);
    }
    refuse("Mach-O load audit has no load commands: $path") unless @loads;
    return @loads;
}

sub verify_macho_loads {
    my ($input_path, $expected_path, $output_path) = @_;
    my @actual = parse_objdump_loads($input_path);
    my $expected = bytes($expected_path);
    refuse('expected Mach-O load list contains NUL or CR')
        if $expected =~ /[\0\r]/;
    my @expected = split /\n/, $expected, -1;
    pop @expected if @expected && $expected[-1] eq '';
    for my $record (@expected) {
        my @field = split /\t/, $record, -1;
        refuse('expected Mach-O load record must have kind/path/compat/current')
            unless @field == 4 && !grep { !length($_) } @field;
    }
    refuse('Mach-O load records or order changed')
        unless join("\0", @actual) eq join("\0", @expected);
    open my $out, '>:raw', $output_path
        or refuse("cannot write $output_path: $!");
    print {$out} join("\n", @actual), "\n";
    close $out or refuse("cannot close $output_path: $!");
    print "Mach-O loads: exact " . scalar(@actual) .
          " kind/path/compat/current records\n";
}

sub normalize_dispatch_errors {
    my ($input_path, $subject_prefix, $output_path) = @_;
    refuse('Dispatch diagnostic subject prefix must be an absolute path')
        unless defined($subject_prefix) &&
               File::Spec->file_name_is_absolute($subject_prefix) &&
               $subject_prefix !~ /[\x00-\x1f\x7f]/;
    my $input = bytes($input_path);
    refuse("Dispatch diagnostic input contains NUL: $input_path")
        if $input =~ /\0/;
    $input =~ s/\r\n/\n/g;
    my @headlines;
    for my $line (split /\n/, $input, -1) {
        next unless $line =~ /: (?:fatal )?error:/ ||
                    $line =~ /\A(?:fatal )?error:/;
        if (index($line, $subject_prefix) == 0) {
            $line = '<SUBJECT>' . substr($line, length($subject_prefix));
        }
        push @headlines, $line;
    }
    refuse("Dispatch diagnostic input has no error headlines: $input_path")
        unless @headlines;
    open my $out, '>:raw', $output_path
        or refuse("cannot write $output_path: $!");
    print {$out} join("\n", @headlines), "\n";
    close $out or refuse("cannot close $output_path: $!");
    print "Dispatch diagnostics: " . scalar(@headlines) .
          " normalized error headlines\n";
}

sub verify_tree_manifest {
    my ($root_arg, $manifest_path) = @_;
    my $root = abs_path($root_arg);
    refuse("manifest root is not a directory: $root_arg")
        unless defined($root) && -d $root;
    my @fields = split /\0/, bytes($manifest_path), -1;
    refuse('tree manifest must end in NUL') unless @fields && $fields[-1] eq '';
    pop @fields;
    refuse('tree manifest must contain SHA/path pairs') if @fields % 2;
    my %expected;
    while (@fields) {
        my $hash = shift @fields;
        my $rel = shift @fields;
        assert_hash($hash, "tree manifest hash for $rel");
        refuse("unsafe path in tree manifest: $rel")
            if !length($rel) || File::Spec->file_name_is_absolute($rel) ||
               grep { $_ eq '' || $_ eq '.' || $_ eq '..' }
                    File::Spec->splitdir($rel);
        refuse("duplicate path in tree manifest: $rel") if exists $expected{$rel};
        $expected{$rel} = $hash;
    }
    refuse('tree manifest must not be empty') unless keys %expected;

    my @disk;
    find({
        no_chdir => 1,
        wanted => sub {
            refuse("manifest tree contains a symlink: $File::Find::name")
                if -l $File::Find::name;
            return if -d $File::Find::name;
            refuse("manifest tree contains a non-regular file: $File::Find::name")
                unless -f $File::Find::name;
            my $rel = File::Spec->abs2rel($File::Find::name, $root);
            $rel =~ s{\\}{/}g;
            push @disk, $rel;
        },
    }, $root);
    @disk = sort @disk;
    my @wanted = sort keys %expected;
    refuse('manifest-tree file inventory changed')
        unless join("\0", @disk) eq join("\0", @wanted);
    for my $rel (@wanted) {
        my $got = sha_file("$root/$rel");
        refuse("manifest-tree hash changed for $rel: expected $expected{$rel}, got $got")
            unless $got eq $expected{$rel};
    }
    print "manifest tree: exact " . scalar(@wanted) . "-file subject\n";
}

sub shell_quote {
    my ($value) = @_;
    $value =~ s/'/'"'"'/g;
    return "'$value'";
}

sub emit_env {
    my ($p) = @_;
    my %env = (
        OC_CLANG_VERSION => $p->{toolchain}{clang_version},
        OC_CLANGXX_SHA => $p->{toolchain}{clangxx_sha256},
        OC_COMMIT => $p->{repository}{commit},
        OC_CONCURRENCY_MODULE_REL => $p->{toolchain}{concurrency_module_relative},
        OC_CONCURRENCY_MODULE_SHA => $p->{toolchain}{concurrency_module_sha256},
        OC_CONCURRENCY_MODULE_BUNDLE_REL =>
            $p->{isolated_inputs}{concurrency_module}{bundle_relative},
        OC_CORE_COUNT => $p->{core_sources}{swift_file_count},
        OC_CORE_DIGEST => $p->{core_sources}{sha256},
        OC_DISPATCH_DYLIB => $p->{dispatch_boundary}{libdispatch_path},
        OC_DISPATCH_SHA => $p->{dispatch_boundary}{libdispatch_sha256},
        OC_DISPATCH_TBD => $p->{dispatch_boundary}{libswift_dispatch_tbd_path},
        OC_DISPATCH_TBD_SHA => $p->{dispatch_boundary}{libswift_dispatch_tbd_sha256},
        OC_DISPATCH_FAILURE_EXIT => $p->{dispatch_boundary}{expected_failure_exit},
        OC_DISPATCH_INTERFACE_ERROR_COUNT =>
            $p->{dispatch_boundary}{expected_interface_error_count},
        OC_DISPATCH_INTERFACE_ERROR_LINE =>
            $p->{dispatch_boundary}{expected_interface_error_line},
        OC_DISPATCH_SOURCE_ERROR_COUNT =>
            $p->{dispatch_boundary}{expected_source_error_count},
        OC_DISPATCH_SOURCE_ERROR_LINE =>
            $p->{dispatch_boundary}{expected_source_error_line},
        OC_EXPECT_MISSING_EXIT => $p->{oracles}{missing_dylib_exit},
        OC_EXPECT_MISSING_LINE => $p->{oracles}{missing_dylib_line},
        OC_EXPECT_MISSING_STREAM => $p->{oracles}{missing_dylib_stream},
        OC_EXPECT_MUTATED_EXIT => $p->{oracles}{mutated_exit},
        OC_EXPECT_MUTATED_LINE => $p->{oracles}{mutated_line},
        OC_EXPECT_MUTATED_STREAM => $p->{oracles}{mutated_stream},
        OC_EXPECT_POSITIVE_EXIT => $p->{oracles}{positive_exit},
        OC_EXPECT_POSITIVE_LINE => $p->{oracles}{positive_line},
        OC_EXPECT_POSITIVE_STREAM => $p->{oracles}{positive_stream},
        OC_EXPECT_REENTRANT_EXIT => $p->{oracles}{reentrant_exit},
        OC_EXPECT_REENTRANT_LINE => $p->{oracles}{reentrant_line},
        OC_EXPECT_REENTRANT_STREAM => $p->{oracles}{reentrant_stream},
        OC_HELPER_PATCHED_SHA => $p->{helper_patch}{patched_sha256},
        OC_HELPER_OBJECT_SHA => $p->{helper_patch}{patched_object_sha256},
        OC_HELPER_PATCH_REL => $p->{helper_patch}{patch_asset},
        OC_HELPER_REL => $p->{helper_patch}{path},
        OC_HELPER_UPSTREAM_SHA => $p->{helper_patch}{upstream_sha256},
        OC_LLD_VERSION => $p->{toolchain}{lld_version},
        OC_LLD_SHA => $p->{toolchain}{lld_sha256},
        OC_MACHORUN_SHA => $p->{toolchain}{machorun_sha256},
        OC_NM_SHA => $p->{toolchain}{nm_sha256},
        OC_OBJDUMP_SHA => $p->{toolchain}{objdump_sha256},
        OC_REPOSITORY_URL => $p->{repository}{url},
        OC_SDK => $p->{toolchain}{sdk_path},
        OC_SWIFT_MODULE_REL => $p->{toolchain}{swift_module_relative},
        OC_SWIFT_MODULE_SHA => $p->{toolchain}{swift_module_sha256},
        OC_SWIFT_MODULE_BUNDLE_REL =>
            $p->{isolated_inputs}{swift_module}{bundle_relative},
        OC_SWIFT_VERSION => $p->{toolchain}{swift_version},
        OC_SWIFTC_SHA => $p->{toolchain}{swiftc_sha256},
        OC_CONTAINER_IMAGE_ID => $p->{toolchain}{container_image_id},
        OC_TARGET => $p->{toolchain}{target},
    );
    for my $path (@LINK_KEYS) {
        my $name = $path;
        $name =~ s{[^A-Za-z0-9]}{_}g;
        $env{"OC_LINK_SHA$name"} = $p->{link_inputs}{$path};
    }
    for my $key (sort keys %env) {
        print "$key=" . shell_quote("$env{$key}") . "\n";
    }
}

sub main {
    my ($mode, $policy_path, @args) = @ARGV;
    refuse('usage: policy_tool.pl MODE POLICY [ARGS...]')
        unless defined $mode && defined $policy_path;
    my $policy = load_policy($policy_path);
    if ($mode eq 'assets') {
        refuse('assets mode needs TOOL_ROOT') unless @args == 1;
        verify_assets($policy, $args[0]);
        print "assets: exact " . scalar(@ASSET_KEYS) . "-file subject\n";
    } elsif ($mode eq 'attest') {
        refuse('attest mode needs REPO LIST_NUL AUDIT_JSON') unless @args == 3;
        attest_sources($policy, $policy_path, @args);
    } elsif ($mode eq 'runtime') {
        refuse('runtime mode needs ROOT') unless @args == 1;
        audit_runtime($policy, $args[0]);
    } elsif ($mode eq 'tree') {
        refuse('tree mode needs NAME ROOT MANIFEST_NUL AUDIT_JSON')
            unless @args == 4;
        attest_input_tree($policy, @args);
    } elsif ($mode eq 'dispatch') {
        refuse('dispatch mode needs WORK_ROOT AUDIT_JSON') unless @args == 2;
        audit_dispatch($policy, @args);
    } elsif ($mode eq 'verify-loads') {
        refuse('verify-loads mode needs OBJDUMP EXPECTED OUTPUT') unless @args == 3;
        verify_macho_loads(@args);
    } elsif ($mode eq 'normalize-dispatch-errors') {
        refuse('normalize-dispatch-errors mode needs INPUT SUBJECT_PREFIX OUTPUT')
            unless @args == 3;
        normalize_dispatch_errors(@args);
    } elsif ($mode eq 'verify-tree') {
        refuse('verify-tree mode needs ROOT MANIFEST_NUL') unless @args == 2;
        verify_tree_manifest(@args);
    } elsif ($mode eq 'env') {
        refuse('env mode takes no extra arguments') if @args;
        emit_env($policy);
    } else {
        refuse("unknown mode: $mode");
    }
    return 0;
}

my $rc = eval { main(); 0 };
if ($@) {
    my $error = $@;
    $error =~ s/\s+\z//;
    print STDERR "REFUSED: $error\n";
    exit 1;
}
exit $rc;
