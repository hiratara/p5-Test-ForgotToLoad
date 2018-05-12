use strict;
use Test::More import => [qw(done_testing)];
use Test::ForgotToLoad qw(
    %WELLKNOWN_DEPENDENCIES
    all_forgot_to_load_ok
);

%WELLKNOWN_DEPENDENCIES = (
    PPI => [
        'PPI::Document'
    ],
);
all_forgot_to_load_ok;

done_testing;
