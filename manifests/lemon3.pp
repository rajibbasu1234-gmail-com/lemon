class s_lemon::lemon3 {

  include s_lemon

  # We want to send the HSTS header, so enable the headers module.
  apache::module { 'headers': ensure => present }

  file { '/srv/www/spdb':
    ensure => directory,
  }

  include spdb::idpmetadata

}
