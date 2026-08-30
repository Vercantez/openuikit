#!/usr/bin/env perl
use strict;
use warnings;

# Fail-closed manifests for the upstream sources consumed by build_full.sh.
# The existing production image deliberately has Perl but not Python, so this
# is dependency-free beyond core modules already used elsewhere in the build.
# This graph has no swift-system checkout: its `os` compatibility module is the
# project-owned full/foundation/os-module/os.swift and is already covered by
# uihelpers_subject.sh's project-source bracket.

use Cwd qw(abs_path);
use Digest::SHA qw(sha1_hex sha256_hex);
use IPC::Open3;
use Symbol qw(gensym);

my %SPECS = (
    'swift-foundation' => {
        commit => 'c6793ef0c19c2cbaeba5a0e52078f129afc7dcfc',
        tree   => '4651798679b98e27383ca3626434fb128f191486',
        groups => [
            ['foundation-swift', 'Sources/FoundationEssentials', '.swift'],
            ['foundation-c-sources', 'Sources/_FoundationCShims', '.c'],
            # Every tracked include-directory file is a possible Clang-module
            # or transitive-header input, so the complete subtree is pinned.
            ['foundation-c-includes', 'Sources/_FoundationCShims/include', undef],
        ],
    },
    'swift-collections' => {
        commit => '9bf03ff58ce34478e66aaee630e491823326fd06',
        tree   => '5e4de96f40ccf147dab967f38cb7988ecd933c27',
        groups => [
            ['collections-internal-utilities', 'Sources/InternalCollectionsUtilities', '.swift'],
            ['collections-ordered', 'Sources/OrderedCollections', '.swift'],
            ['collections-rope', 'Sources/RopeModule', '.swift'],
        ],
    },
);

sub refuse {
    my ($message) = @_;
    die "pinned_inputs: REFUSING -- $message\n";
}

sub controlled_environment {
    my %environment = map { $_ => $ENV{$_} } grep { index($_, 'GIT_') != 0 } keys %ENV;
    $environment{GIT_CONFIG_GLOBAL} = '/dev/null';
    $environment{GIT_CONFIG_NOSYSTEM} = '1';
    $environment{GIT_NO_REPLACE_OBJECTS} = '1';
    $environment{GIT_OPTIONAL_LOCKS} = '0';
    $environment{LANG} = 'C';
    $environment{LC_ALL} = 'C';
    return %environment;
}

sub git_bytes {
    my ($repo, @arguments) = @_;
    local %ENV = controlled_environment();
    my @command = (
        'git', '-c', 'core.fsmonitor=false', '-c', 'core.hooksPath=/dev/null',
        '-C', $repo, @arguments,
    );
    my $error = gensym;
    my ($input, $output);
    my $pid;
    eval { $pid = open3($input, $output, $error, @command); 1 }
        or refuse("cannot execute git for $repo: $@");
    close $input;
    binmode $output;
    binmode $error;
    local $/;
    my $stdout = <$output> // '';
    my $stderr = <$error> // '';
    waitpid($pid, 0);
    my $status = $? >> 8;
    refuse("git @arguments failed for $repo: $stderr") if $status != 0;
    return $stdout;
}

sub git_text {
    my ($repo, @arguments) = @_;
    my $value = git_bytes($repo, @arguments);
    $value =~ s/\s+\z//;
    return $value;
}

sub safe_relative_path {
    my ($path) = @_;
    refuse("unsafe pinned Git path: $path")
        if $path eq '' || $path =~ m{^/} || $path =~ /[\r\n]/ || $path =~ m{//};
    for my $component (split m{/}, $path, -1) {
        refuse("unsafe pinned Git path: $path")
            if $component eq '' || $component eq '.' || $component eq '..';
    }
}

sub parse_tree {
    my ($root, $commit) = @_;
    my $object_format = git_text($root, 'rev-parse', '--show-object-format');
    refuse("unsupported Git object format for $root: $object_format")
        unless $object_format eq 'sha1' || $object_format eq 'sha256';
    my $raw = git_bytes($root, 'ls-tree', '-r', '--full-tree', '-z', $commit);
    my %entries;
    for my $record (split /\0/, $raw, -1) {
        next if $record eq '';
        my ($metadata, $path) = split /\t/, $record, 2;
        refuse("unparseable pinned Git tree entry in $root") unless defined $path;
        my ($mode, $kind, $object_id) = split / /, $metadata, 3;
        refuse("unparseable pinned Git metadata in $root")
            unless defined $mode && defined $kind && defined $object_id;
        safe_relative_path($path);
        refuse("duplicate pinned Git path in $root: $path") if exists $entries{$path};
        $entries{$path} = [$mode, $kind, $object_id];
    }
    return (\%entries, $object_format);
}

sub read_file_bytes {
    my ($path) = @_;
    open my $handle, '<:raw', $path or refuse("cannot read pinned input $path: $!");
    local $/;
    my $payload = <$handle>;
    close $handle or refuse("cannot close pinned input $path: $!");
    return defined $payload ? $payload : '';
}

sub blob_object_id {
    my ($payload, $object_format) = @_;
    my $framed = 'blob ' . length($payload) . "\0" . $payload;
    return $object_format eq 'sha1' ? sha1_hex($framed) : sha256_hex($framed);
}

sub selected_by_group {
    my ($path, $group) = @_;
    my ($name, $prefix, $suffix) = @$group;
    return 0 unless index($path, "$prefix/") == 0;
    return 1 unless defined $suffix;
    return length($path) >= length($suffix)
        && substr($path, -length($suffix)) eq $suffix;
}

sub verify_repo {
    my ($root_argument, $name) = @_;
    my $spec = $SPECS{$name} or refuse("unknown pinned repository: $name");
    my $root = abs_path($root_argument);
    refuse("missing $name checkout: $root_argument") unless defined $root && -d $root;
    my $top_level = abs_path(git_text($root, 'rev-parse', '--show-toplevel'));
    refuse("$name path is not the checkout root: $root")
        unless defined $top_level && $top_level eq $root;
    my $head = git_text($root, 'rev-parse', '--verify', 'HEAD');
    refuse("$name HEAD $head != pinned $spec->{commit}") unless $head eq $spec->{commit};
    my $tree = git_text($root, 'rev-parse', 'HEAD^{tree}');
    refuse("$name tree $tree != pinned $spec->{tree}") unless $tree eq $spec->{tree};

    # Include ignored paths. This closes the exact .build*/Injected.swift
    # blind spot in ordinary --porcelain --untracked-files=all checks.
    my $status = git_bytes(
        $root, 'status', '--porcelain=v1', '-z', '--untracked-files=all', '--ignored=matching'
    );
    if ($status ne '') {
        my ($first) = split /\0/, $status, 2;
        refuse("$name checkout has tracked/untracked/ignored drift: $first");
    }

    my ($entries, $object_format) = parse_tree($root, $spec->{commit});
    my @inputs;
    my %seen;
    for my $group (@{$spec->{groups}}) {
        my ($group_name) = @$group;
        my @paths = sort grep { selected_by_group($_, $group) } keys %$entries;
        refuse("$name pinned group is empty: $group_name") unless @paths;
        for my $relative (@paths) {
            refuse("$name input belongs to multiple groups: $relative") if $seen{$relative}++;
            my ($mode, $kind, $object_id) = @{$entries->{$relative}};
            refuse("unsupported pinned entry for $relative: $mode $kind")
                unless $kind eq 'blob' && ($mode eq '100644' || $mode eq '100755' || $mode eq '120000');
            my $path = "$root/$relative";
            my @metadata = lstat($path);
            refuse("missing pinned worktree input: $relative") unless @metadata;
            my $payload;
            if ($mode eq '120000') {
                refuse("worktree type drift: $relative") unless -l _;
                $payload = readlink($path);
                refuse("cannot read pinned symlink $relative: $!") unless defined $payload;
            } else {
                refuse("worktree type drift: $relative") unless -f _ && !-l _;
                my $expected_executable = $mode eq '100755' ? 1 : 0;
                my $actual_executable = ($metadata[2] & 0100) ? 1 : 0;
                refuse("worktree executable-mode drift: $relative")
                    unless $actual_executable == $expected_executable;
                $payload = read_file_bytes($path);
            }
            refuse("worktree content drift from pinned Git blob: $relative")
                unless blob_object_id($payload, $object_format) eq $object_id;
            push @inputs, {
                group => $group_name,
                path => $relative,
                mode => $mode,
                object_id => $object_id,
                sha256 => sha256_hex($payload),
            };
        }
    }
    return { name => $name, root => $root, spec => $spec, inputs => \@inputs };
}

sub state_digest {
    my (@repositories) = @_;
    my $sha = Digest::SHA->new(256);
    for my $repository (@repositories) {
        my $spec = $repository->{spec};
        $sha->add("repo\t$repository->{name}\t$spec->{commit}\t$spec->{tree}\n");
        for my $input (@{$repository->{inputs}}) {
            $sha->add(
                "input\t$repository->{name}\t$input->{group}\t$input->{mode}\t" .
                "$input->{object_id}\t$input->{sha256}\t$input->{path}\n"
            );
        }
    }
    return $sha->hexdigest;
}

sub usage {
    refuse(
        'usage: pinned_inputs.pl verify --swift-foundation PATH --swift-collections PATH ' .
        '[--digest-only] | list --repository NAME --repo PATH --group NAME'
    );
}

my $command = shift @ARGV // '';
eval {
    if ($command eq 'verify') {
        my ($foundation, $collections, $digest_only);
        while (@ARGV) {
            my $option = shift @ARGV;
            if ($option eq '--swift-foundation') { $foundation = shift @ARGV; }
            elsif ($option eq '--swift-collections') { $collections = shift @ARGV; }
            elsif ($option eq '--digest-only') { $digest_only = 1; }
            else { usage(); }
        }
        usage() unless defined $foundation && defined $collections;
        my @repositories = (
            verify_repo($foundation, 'swift-foundation'),
            verify_repo($collections, 'swift-collections'),
        );
        my $digest = state_digest(@repositories);
        if ($digest_only) {
            print "$digest\n";
        } else {
            my @counts;
            for my $repository (@repositories) {
                for my $group (@{$repository->{spec}{groups}}) {
                    my ($group_name) = @$group;
                    my $count = grep { $_->{group} eq $group_name } @{$repository->{inputs}};
                    push @counts, "$group_name=$count";
                }
            }
            print "PINNED_UPSTREAM_INPUTS_OK sha256=$digest @counts\n";
        }
    } elsif ($command eq 'list') {
        my ($repository_name, $repo, $group_name);
        while (@ARGV) {
            my $option = shift @ARGV;
            if ($option eq '--repository') { $repository_name = shift @ARGV; }
            elsif ($option eq '--repo') { $repo = shift @ARGV; }
            elsif ($option eq '--group') { $group_name = shift @ARGV; }
            else { usage(); }
        }
        usage() unless defined $repository_name && defined $repo && defined $group_name;
        my $repository = verify_repo($repo, $repository_name);
        my %known_groups = map { $_->[0] => 1 } @{$repository->{spec}{groups}};
        refuse("unknown $repository_name group: $group_name") unless $known_groups{$group_name};
        for my $input (@{$repository->{inputs}}) {
            print "$repository->{root}/$input->{path}\n" if $input->{group} eq $group_name;
        }
    } else {
        usage();
    }
    1;
} or do {
    my $error = $@ || 'unknown failure';
    print STDERR $error;
    exit 2;
};
