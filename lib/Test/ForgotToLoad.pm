package Test::ForgotToLoad;
use 5.008_005;
use strict;
use warnings;
use Exporter qw(import);
use File::Find ();
use PPI;
use Test::Builder ();
use Test::More import => [qw(diag is ok)];

our $VERSION = '0.01';
our @EXPORT_OK = qw(
    %WELLKNOWN_DEPENDENCIES
    forgot_to_load_ok
    all_forgot_to_load_ok
);

our $CLASS_NAME_REGEXP = qr/^[A-Z][A-Za-z0-9]+(?:::[A-Z][A-Za-z0-9]+)*$/;

# (class => [auto_used_class1, auto_used_class2, ...], ...)
our %WELLKNOWN_DEPENDENCIES;

sub _get_defined_classes ($) {
    my $doc = shift;

    my $packages = $doc->find('PPI::Statement::Package');
    $packages or die "[BUG] no package definitions found: $doc";

    my @defined_classes;
    for my $package (@$packages) {
        my $package_words = $package->find(sub {
            my ($root, $node) = @_;
            $node->isa('PPI::Token::Word') and $node->content eq 'package';
        });
        $package_words or die "[BUG] no package keywords found: $package";

        @$package_words == 1 or
            die "[BUG] too many package keywords: $package";
        my ($package_word) = @$package_words;

        my $class = $package_word->snext_sibling;
        $class or die "[BUG] found an empty package keyword: $package";
        $class->isa('PPI::Token::Word')
            or die "[BUG] unexpected use of package: $package";
        push @defined_classes, $class->content;
    }

    @defined_classes;
}

sub _get_used_classes ($) {
    my $doc = shift;

    my $includes = $doc->find('PPI::Statement::Include');
    return unless $includes;

    my @used_classes;
    for my $include (@$includes) {
        my $use_words = $include->find(sub {
            my ($root, $node) = @_;
            $node->isa('PPI::Token::Word') and
            $node->content =~ /^(?:use|require)$/;
        });
        next unless $use_words;

        @$use_words == 1 or die "[BUG] too many use keywords: $include";
        my ($use_word) = @$use_words;

        my $class = $use_word->snext_sibling;
        $class or die "[BUG] found an empty use keyword: $include";
        if ($class->isa('PPI::Token::Word')) {
            push @used_classes, $class->content,
                 @{$WELLKNOWN_DEPENDENCIES{$class->content} // []};
        } elsif ($class->isa('PPI::Token::Number')) {
            # specified perl version. just ignore it
        } else {
            warn "unexpected use of use: $include, refs=", ref $class;
        }
    }

    @used_classes;
}

sub _get_callee_classes ($) {
    my $doc = shift;

    # extract all usage of ->
    my $operators = $doc->find(sub {
                                   my ($root, $node) = @_;
                                   $node->isa('PPI::Token::Operator') and $node->content eq '->';
                               });
    return unless $operators;

    my %required_class; # classes loaded by UNIVERSAL::required
    my %set_of_callee_classes;
    for (@$operators) {
        my $operand1 = $_->sprevious_sibling;
        $operand1 or die "[BUG] no token found before -> operator: $_";

        my $operand2 = $_->snext_sibling;
        $operand2 or die "[BUG] no token found after -> operator: $_";

        # -> usage except ->meth or ->$meth
        next unless $operand2->isa('PPI::Token::Word') or
            $operand2->isa('PPI::Token::Symbol');

        # except $self
        next unless $operand1->isa('PPI::Token::Word');

        # except shift->, __PACKAGE__->, Some::Class::method->
        next unless $operand1->content =~ $CLASS_NAME_REGEXP;

        my $prev_token = $operand1->sprevious_sibling;

        # except method chains like ->SUPER::hoge->meth
        next if $prev_token and $prev_token->isa('PPI::Token::Operator')
          and $prev_token->content eq '->';

        # you can call ->require for any anonymous classes
        if ($operand2->content eq 'require') {
            $required_class{$operand1->content}++;
            next;
        }

        $set_of_callee_classes{$operand1->content}++;
    }

    grep { ! $required_class{$_} } keys %set_of_callee_classes;
}

sub forgot_to_load_ok ($;$) {
    my ($file, $note) = @_;
    $note //= "$file";

    my $doc = PPI::Document->new($file);

    my %loaded_classes = map { $_ => 1 } _get_defined_classes $doc,
                                         _get_used_classes $doc;
    my @callee_classes = _get_callee_classes $doc;

    my @classes_forgotten_to_load = grep { ! $loaded_classes{$_} }
                                         @callee_classes;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    ok(! @classes_forgotten_to_load, "class used in $file") or do {
        diag <<DIAGNOSTIC for @classes_forgotten_to_load;
    $_ should be loaded
DIAGNOSTIC
    };
}

sub all_forgot_to_load_ok (;$) {
    my $note = shift;
    $note //= __PACKAGE__;

    my @files;
    File::Find::find sub {
        -f && ! /^\./ && /\.pm$/ or return;
        push @files, $File::Find::name;
    } => 'lib/';

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    forgot_to_load_ok $_ for @files;
}

1;
__END__

=encoding utf-8

=head1 NAME

Test::ForgotToLoad - Make sure to load all classes

=head1 SYNOPSIS

  use Test::ForgotToLoad qw(forgot_to_load_ok);
  use Test::More import => [qw(all_forgot_to_load_ok)];

  all_forgot_to_load_ok;
  done_testing;

=head1 DESCRIPTION

Test::ForgotToLoad finds classes that forget to use.

=head1 FUNCTIONS

=head2 C<forgot_to_load_ok($path_to_your_class [, $note])>

Finds classes that forget to use in the C<$path_to_your_class> file.
If all the classes are correctly loaded, the test will succeed.

C<forgot_to_load_ok> uses PPI to find classes used in the file.
It regards the description of form C<< CLASS->method >> as a class.

=head2 C<all_forgot_to_load_ok([$note])>

Check all files in C<lib/> directory using C<forgot_to_load_ok>.

=head1 VARIABLES

=head2 C<%WELLKNOWN_DEPENDENCIES>

Define classes automatically used when you use another one.

  use Test::ForgotToLoad qw(%WELLKNOWN_DEPENDENCIES);

  %WELLKNOWN_DEPENDENCIES = (
      PPI => [
          'PPI::Document',
          'PPI::Statement',
          'PPI::Structure',
          .. snip ..
      ],
  );

=head1 AUTHOR

Masahiro Honma E<lt>hiratara@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2018- Masahiro Honma

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
