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

=cut

sub remove_plugins {
  my ($self, $remove, @plugins) = @_;

  # stolen 100% from @Filter (thanks rjbs!)
  require List::MoreUtils;
  for my $i (reverse 0 .. $#plugins) {
    splice @plugins, $i, 1 if List::MoreUtils::any(sub {
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

B<NOTE>: If you overwrite C<mvp_multivalue_args>
you'll need to include the value of C<plugin_remover_attribute>
(C<-remove> by default) if you want to retain this functionality.
As always, patches and suggestions are welcome.

This role adds a method modifier to C<bundle_config>,
which is the method that the root C<PluginBundle> role requires,
and that C<PluginBundle::Easy> wraps.

=cut
