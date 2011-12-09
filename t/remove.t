# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use lib 't/lib';

my $mod = 'Dist::Zilla::Role::PluginBundle::PluginRemover';
eval "require $mod" or die $@;

use Dist::Zilla::Util;
sub e { Dist::Zilla::Util->expand_config_package_name($_[0]); }

my @plugins = (
  [Foo => e('Foo')],
  [Bar => e('Bar')],
);

  is_deeply
    [ $mod->remove_plugins([qw(Baz)], @plugins) ],
    [ @plugins ],
    'nothing removed';

  is_deeply
    [ $mod->remove_plugins([qw(Foo)], @plugins) ],
    [ [Bar => e('Bar')] ],
    'one removed';

  is_deeply
    [ $mod->remove_plugins([qw(Bar)], @plugins) ],
    [ [Foo => e('Foo')] ],
    'other removed';

  is_deeply
    [ $mod->remove_plugins([qw(Bar Foo)], @plugins) ],
    [ ],
    'nothing left';

done_testing;
