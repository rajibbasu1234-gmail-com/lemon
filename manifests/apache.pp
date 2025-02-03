# $catch_all_cert: the certificate prefix to use for the catch-all and
# default sites. It does not matter which certificate you use, but it must
# exist. Default: 'spdb'.

class s_lemon::apache(
          $entityid           = undef,
          $idp           = 'https://idp.stanford.edu/',
          $idp_metadata_url   = 'https://login.stanford.edu/metadata.xml', 
          $authncontext       = 'https://refeds.org/profile/mfa',
  Boolean $include_shibboleth = true,
  Boolean $enable_passenger   = true,
          $catch_all_cert     = 'spdb',
){

  if (!$entityid) {
    fail('missing entityid parameter')
  }

  if ($include_shibboleth) {
    # Install the shibboleth SP software
    case $facts['os']['distro']['codename'] {
      'stretch', 'jessie': {
        include shibboleth_sp2
      }
      default: {
        include shibboleth_sp3
      }
    }

    # We store the metadata backing file in /var/cache/shibboleth/, so
    # make sure that the directory exists.
    $metadata_backingfile_directory = '/var/cache/shibboleth/'
    file { $metadata_backingfile_directory:
      ensure => directory,
    }

    # Version 3 of Shibboleth SP uses slightly different configuration
    # syntax.  So, we set the version of the software based on the OS. The
    # only OS we are still using that uses SP version 2 is stretch.
    #
    # The value $sp_value is used in shibboleth2.xml.erb
    if ($facts['os']['distro']['codename'] == 'stretch') {
      $sp_version = "2"
    } else {
      $sp_version = "3"
    }
    file { '/etc/shibboleth/shibboleth2.xml':
      ensure  => present,
      content => template('s_lemon/etc/shibboleth/shibboleth2.xml.erb')
    }

    file { '/etc/shibboleth/attribute-map.xml':
      ensure  => present,
      source => 'puppet:///modules/s_lemon/etc/shibboleth/attribute-map.xml',
    }
  }

  # We want non-root users to be able to some Apache things (e.g.,
  # restart, read logs, etc.). This class also instantiates the /srv/www
  # file resource.
  include apache::local

  # We manage our own apache2.conf file.
  file { '/etc/apache2/apache2.conf':
    ensure  => present,
    content => template('s_lemon/etc/apache2/apache2.conf.erb')
  }

  # Rotate some apache log files.
  base::newsyslog::config { 'apache2':
    frequency => 'daily',
    directory => '/var/log/apache2',
    restart   => 'run /usr/sbin/service apache2 reload',
    logs      => ['error.log', 'other_vhosts_access.log'],
    log_mode  => '0644',
    log_group => 'webconfig',
  }
  file { '/var/log/apache2/OLD':
    ensure => directory,
    mode   => '0755',
    owner  => root,
    group  => root;
  }

  # Enable the "zzz-default" site. This is the catch-all for
  # requests that do not match any of the other server names.
  # The reason we use "zzz-" is, you guessed it, so that it will be the
  # LAST configuration Apache considers when deciding which VirtualHost to
  # use.
  apache::site { 'zzz-default':
    content => template('s_lemon/etc/apache2/sites-available/zzz-default.conf.erb')
  }

  # We want the _first_ virtual host to NOT match any server name. This
  # way, any client that connects that does NOT support SNI will get
  # 000-catch-all. For example, the F5 health check monitors.
  apache::site { '000-catch-all':
    content => template('s_lemon/etc/apache2/sites-available/000-catch-all.conf.erb')
  }

  # Set systemd's PrivateTmp to "false". Otherwise Apache applications cannot
  # access /var/tmp
  class { 'su_apache::systemd_override':
    private_tmp => false
  }

}
