print "1..1\n";

use Data::Pivoter;

if ($Data::Pivoter::VERSION eq '0.07') {
    print "ok 1\n";
} else {
    print "not ok 1\n";
}
