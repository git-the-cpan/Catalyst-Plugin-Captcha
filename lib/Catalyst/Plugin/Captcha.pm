package Catalyst::Plugin::Captcha;

use strict;
use warnings;
use GD::SecurityImage;
use HTTP::Date;

our $VERSION = '0.02';

sub setup {
    my $c = shift;

    $c->config->{captcha}->{session_name} = 'captcha_string';
    $c->config->{captcha}->{new} ||= {};
    $c->config->{captcha}->{create} ||= [];
    $c->config->{captcha}->{particle} ||= [];
    $c->config->{captcha}->{out} ||= {};

    return $c->NEXT::setup(@_);
}

sub create_captcha {
    my $c = shift;
    my $conf = $c->config->{captcha};

    my $image = GD::SecurityImage->new(%{$conf->{new}});
    $image->random();
    $image->create(@{$conf->{create}});
    $image->particle(@{$conf->{particle}});

    my ( $image_data, $mime_type, $random_string ) = $image->out(%{$conf->{out}});

    $c->session->{ $c->config->{captcha}->{session_name} } = $random_string;

    $c->res->headers->expires(time());
    $c->res->headers->header('Last-Modified' => HTTP::Date::time2str);
    $c->res->headers->header('Pragma' => 'no-cache');
    $c->res->headers->header('Cache-Control' => 'no-cache');

    $c->res->content_type("image/$mime_type");
    $c->res->output($image_data);
}

sub validate_captcha {
    my ($c, $verify) = @_;
    my $string = $c->captcha_string;
    return ($verify && $string && $verify eq $string);
}


sub captcha_string {
    my $c = shift;
    return  $c->session->{ $c->config->{captcha}->{session_name} };
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Catalyst::Plugin::Captcha - create and validate Captcha for Catalyst

=head1 SYNOPSIS

  use Catalyst qw/Captcha/;

  MyApp->config->{captcha} = {
    session_name => 'captcha_string',
    new => {
      width => 80,
      height => 30,
      lines => 7,
      gd_font => 'giant',
    },
    create => [qw/normal rect/],
    particle => [100],
    out => {force => 'jpeg'}
  };

  sub captcha : Local {
    my ($self, $c) = @_;
    $c->create_captcha();
  }

  sub do_post : Local {
    my ($self, $c) = @_;
    if ($c->validate_captcha($c->req->param('validate')){
      ..
    } else {
      ..
    }
  }

  #validate with CP::FormValidator::Simple
  sub do_post : Local {
    my ($self, $c) = @_;
    $c->form(
      validate => [['EQUAL_TO',$c->captcha_string]]
    )
  }

=head1 DESCRIPTION

This plugin create, validate Captcha.

Note: This plugin uses L<GD::SecurityImage> and requires a session plugins like L<Catalyst::Plugin::Session>

=head1 METHODS

=head2 create_captcha

Create Captcha image and output it.

=head2 validate_captcha

  $c->validate_captcha($key);

validate key

=head2 captcha_string

Return a string for validation which is stroed in session.

=head1 SEE ALSO

L<GD::SecurityImage>, L<Catalyst>

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo@nomadscafe.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Masahiro Nagano

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
