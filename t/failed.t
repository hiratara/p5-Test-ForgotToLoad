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
        name => q(class used in t/Invalid.pm),
        diag => "    Other::Class should be loaded",
    },
), 'check Invalid.pm';

done_testing;
