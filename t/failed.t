use strict;
use warnings;
use lib qw(t/);
use Test::Tester import => [qw(check_test)];
use Test::ForgotToLoad qw(forgot_to_load_ok);
use Test::More import => [qw(use_ok done_testing)];

use_ok 'Invalid';
check_test(
    sub {
        forgot_to_load_ok 't/Invalid.pm';
    }, {
        ok => 0,
        name => q(t/Invalid.pm: Other::Class sould be loaded),
        diag => "         got: '1'\n    expected: '0'",
    },
), 'check Invalid.pm';

done_testing;
