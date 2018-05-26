# NAME

Test::ForgotToLoad - Make sure to load all classes

# SYNOPSIS

    use Test::ForgotToLoad qw(forgot_to_load_ok);
    use Test::More import => [qw(all_forgot_to_load_ok)];

    all_forgot_to_load_ok;
    done_testing;

# DESCRIPTION

Test::ForgotToLoad finds classes that forget to use.

# FUNCTIONS

## `forgot_to_load_ok($path_to_your_class [, $note])`

Finds classes that forget to use in the `$path_to_your_class` file.
If all the classes are correctly loaded, the test will succeed.

`forgot_to_load_ok` uses PPI to find classes used in the file.
It regards the description of form `CLASS->method` as a class.

## `all_forgot_to_load_ok([$note])`

Check all files in `lib/` directory using `forgot_to_load_ok`.

# VARIABLES

## `%WELLKNOWN_DEPENDENCIES`

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

# AUTHOR

Masahiro Honma <hiratara@cpan.org>

# COPYRIGHT

Copyright 2018- Masahiro Honma

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO
