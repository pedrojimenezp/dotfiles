#!/usr/bin/perl
# Replaces common secrets in the text on stdin with *** and prints the result. Reads and writes bytes, so a missing final newline stays missing.
# Keeps the part that says what the value is (key name, token prefix, auth scheme) and is safe to run twice.
use strict;
use warnings;

my $text = do { local $/; <STDIN> };
$text = '' unless defined $text;
my @lines = split /(?<=\n)/, $text;

# Key names whose value is masked in key=value and key: value pairs.
my $key = qr/[\w-]*(?:password|passwd|secret|token|api_key|apikey|access_key|private_key)[\w-]*/i;

my ($in_pem, $pem_masked) = (0, 0);
for my $line (@lines) {
    # PEM private key: the BEGIN and END lines stay, the body becomes one *** line.
    if ($in_pem) {
        if ($line =~ /-----END [A-Z ]*PRIVATE KEY-----/) { $in_pem = 0 }
        elsif ($pem_masked) { $line = '' }
        else { $line = $line =~ /\n\z/ ? "***\n" : '***'; $pem_masked = 1 }
        next;
    }
    ($in_pem, $pem_masked) = (1, 0) if $line =~ /-----BEGIN [A-Z ]*PRIVATE KEY-----(?!.*-----END)/;

    # Authorization header, keeping the scheme.
    $line =~ s/(\bAuthorization\s*:\s*(?:(?:Bearer|Basic|Digest|Token|Negotiate)\s+)?)[^\s'",;]+/$1***/gi;
    $line =~ s/\b(Bearer\s+)(?!\*\*\*)[A-Za-z0-9._~+\/=-]{8,}/$1***/g;

    $line =~ s/\b(gh[pousr]_)[A-Za-z0-9]{20,}/$1***/g;
    $line =~ s/\b(github_pat_)[A-Za-z0-9_]{20,}/$1***/g;
    # sk- keys must hold a digit, so hyphenated words like sk-learn-compat-extension are left alone.
    $line =~ s/\b(sk-(?:ant-|proj-)?)(?=[A-Za-z0-9_-]*\d)[A-Za-z0-9_-]{20,}/$1***/g;
    $line =~ s/\b((?:AKIA|ASIA))[A-Z0-9]{16}\b/$1***/g;
    $line =~ s/\b(xox[abprs]-)[A-Za-z0-9-]{10,}/$1***/g;
    $line =~ s/\beyJ[A-Za-z0-9_-]{5,}\.[A-Za-z0-9_-]{5,}\.[A-Za-z0-9_-]*/eyJ***/g;

    # A quoted value is masked whole, keeping its quotes; an unquoted one up to the next space, quote, comma, semicolon or &.
    $line =~ s{(\b$key["']?\s*[:=]\s*)("[^"]+"|'[^']+'|[^\s"',;&]+)}{
        my ($head, $val) = ($1, $2);
        my $q = $val =~ /^(["'])/ ? $1 : '';
        $head . $q . '***' . $q;
    }gie;
}
print @lines;
