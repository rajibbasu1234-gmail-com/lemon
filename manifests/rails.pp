# Set up a generic Ruby-on-Rails environment
class s_lemon::rails {

  package { 'rails':
    ensure => installed
  }

  file { '/usr/share/spdb/Gemfile.lock':
    ensure => present,
    mode   => '0664',
    owner  => 'root',
    group  => 'www-data',
  }

  # We want to version the entries, so we install the paper_trail gem.
  package { 'paper_trail':
    ensure   => 'installed',
    provider => 'gem',
  }

  package { 'rake':
    ensure   => 'installed',
    provider => 'gem',
  }

  package { 'bootstrap-sass':
    ensure   => 'installed',
    provider => 'gem',
  }

  package { 'strip-attributes':
    ensure   => 'installed',
    provider => 'gem',
  }

}
