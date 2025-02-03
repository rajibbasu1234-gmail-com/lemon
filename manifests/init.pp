# The lemon servers.
class s_lemon(
          $certreq_enabled             = false,
          $samlvalidate_enabled        = false,
          $load_balanced_enabled       = false,
          $extra_users_enabled         = false,
          $crdb_enabled                = false,
          $spdb_enabled                = true,
          $data_access_request_enabled = false,
  Boolean $install_gcp_cloudsql_proxy  = false
){

  include defaults

  # Support information.
  facts::instance {
    'su_group':       value => 'acs-tools';
    'su_munin_group': value => 'acs-tools';
    'su_sysadmin0':   value => 'vivienwu';
    'su_sysadmin1':   value => 'adamhl';
    'su_sysadmin2':   value => 'psr123';
  }

  include s_lemon::apache

  if ($extra_users_enabled) {
    ## Allow extra users to access lemon servers
    include s_lemon::extra_users
  }

  # See heira file for spdb parameter settings.
  if ($spdb_enabled) {
    include ::spdb
  }

  if ($certreq_enabled) {
    # Install the certreq software
    class { 'certreq':
      ensure => present,
    }
  } else {
    # Make sure the certreq software is not installed
    class { 'certreq':
      ensure => absent,
    }
  }

  if ($samlvalidate_enabled) {
    include s_lemon::samlvalidate
  }

  if ($crdb_enabled) {
    include crdb
  }

  if ($sysadmin_dashboard_enabled) {
    include sysadmin_dashboard
  }

  # Turn on load-balancing (if enabled)
  if ($load_balanced_enabled) {
    # Install the bigip pool management helper
    lb::bigip { 'lb':
      ensure      => present,
      signal_port => 9080,
    }
  }

  # Install the .ssh/config file that disables
  # know hosts checking for code.stanford.edu
  file { '/root/.ssh':
    ensure => directory
  }

  file { '/root/.ssh/config':
    ensure  => present,
    source  => 'puppet:///modules/s_lemon/root/dot_ssh/config',
    require => File['/root/.ssh'],
  }

  if ($data_access_request_enabled) {
    class { 'data_access_request':
      ensure => present
    }

    package { 'libapache2-mod-php':
      ensure => installed,
    }

    if ($facts['os']['distro']['codename'] == 'bullseye') {
        apache::module { "php7.4": ensure => present }
    } elsif ($facts['os']['distro']['codename'] == 'bullseye') {
        apache::module { "php7.4": ensure => present }
    } else {
        apache::module { "php7.3": ensure => present }
    }
  } else {
    class { 'data_access_request':
      ensure => absent
    }
  }

  include google_cloud_sdk_package

  if ($::hostname =~ /lemon-dev|lemon-test|lemon-stage/) {

    include package_docker

    # Install the basic auth file for data_access_request
    wallet { 'config/its-idg/data-access-request/apache-basic-auth':
      type  => 'file',
      path  => '/etc/apache2/data-access-request.auth',
      mode  => '0640',
      owner => 'root',
      group => 'www-data',
    }
  }

  $wallet_cloudsql   =  'config/its-idg/gcp-service-account/uit-services-cloudsql-proxy'

  if ($::hostname =~ /lemon-dev|lemon-test|lemon-stage/) {
      $cloudsql_instance =  ['uit-services:us-west1:mysql-stage-8=tcp:3306']
  } else {
      $cloudsql_instance =  ['uit-services:us-west1:mysql-prod-8=tcp:3306']
  }

  if ($install_gcp_cloudsql_proxy) {
    gcp_cloudsql_proxy { 'lemon':
      ensure    => present,
      service_credentials_wallet_name
                => $wallet_cloudsql,
      instances => $cloudsql_instance,
    }
  }

}
