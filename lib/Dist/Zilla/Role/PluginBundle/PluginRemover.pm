# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package Dist::Zilla::Role::PluginBundle::PluginRemover;
# ABSTRACT: Add '-remove' functionality to a bundle

use Moose::Role;
use Dist::Zilla::Util ();

requires 'bundle_config';

=method plugin_remover_attribute

Returns the name of the attribute
containing the array ref of plugins to remove.

Defaults to C<-remove>.

=cut

sub plugin_remover_attribute { '-remove' };

# Stub an empty sub so we can use 'around'.
# A consuming class can overwrite the empty sub
# and the 'around' will modify that sub at composition time.
sub mvp_multivalue_args { }

around mvp_multivalue_args => sub {
  my $orig = shift;
  my $self = shift;
  $self->plugin_remover_attribute, $self->$orig(@_)
};

=method remove_plugins

  $class->remove_plugins(\@to_remove, @plugins);
  $class->remove_plugins(['Foo'], [Foo => 'DZP::Foo'], [Bar => 'DZP::Bar']);

Takes an arrayref of plugin names to remove
(like what will be in the config payload for C<-remove>),
removes them from the list of plugins passed,
and returns the remaining plugins.

This is used by the C<bundle_config> modifier
but is defined separately in case you would like
to use the functionality without the voodoo that occurs
when consuming this role.

The plugin name to match against all plugins can be given as either the plugin
moniker (like you might provide in your config file, expanded via
L<Dist::Zilla::Util/expand_config>), or the unique plugin name used to
differentiate multiple plugins of the same type. For example, in this
configuration:

    [Foo::Bar / plugin 1]
    [Foo::Bar / plugin 2]

passing C<'Foo::Bar'> to C<remove_plugins> will remove both these plugins from
the configuration, but only the first is removed when passing C<'plugin 1'>.

=cut

sub remove_plugins {
  my ($self, $remove, @plugins) = @_;

  # plugin specifications look like:
  # [ plugin_name, plugin_class, arguments ]

  # stolen 99% from @Filter (thanks rjbs!)
  require List::MoreUtils;
  for my $i (reverse 0 .. $#plugins) {
    splice @plugins, $i, 1 if List::MoreUtils::any(sub {
      $plugins[$i][0] eq $_
        or
      $plugins[$i][1] eq Dist::Zilla::Util->expand_config_package_name($_)
    }, @$remove);
  }

  return @plugins;
}

around bundle_config => sub {
  my ($orig, $class, $section) = @_;

  # is it better to delete this or allow the bundle to see it?
  my $remove = $section->{payload}->{ $class->plugin_remover_attribute };

  my @plugins = $orig->($class, $section);

  return @plugins unless $remove;

  return $class->remove_plugins($remove, @plugins);
};

1;

=for Pod::Coverage mvp_multivalue_args

=head1 SYNOPSIS

  # in Dist::Zilla::PluginBundle::MyBundle

  with (
    'Dist::Zilla::Role::PluginBundle', # or PluginBundle::Easy
    'Dist::Zilla::Role::PluginBundle::PluginRemover'
  );

  # PluginRemover should probably be last
  # (unless you're doing something more complex)

=head1 DESCRIPTION

This role enables your L<Dist::Zilla> Plugin Bundle
to automatically remove any plugins specified
by the C<-remove> attribute
(like L<@Filter|Dist::Zilla::PluginBundle::Filter> does):

  [@MyBundle]
  -remove = PluginIDontWant
  -remove = OtherDumbPlugin

If you want to use an attribute named C<-remove> for your own bundle
you can override the C<plugin_remover_attribute> sub
to define a different attribute name:

  # in your bundle package
  sub plugin_remover_attribute { 'scurvy_cur' }

This role adds a method modifier to C<bundle_config>,
which is the method that the root C<PluginBundle> role requires,
and that C<PluginBundle::Easy> wraps.

=cut
