class s_lemon::samlvalidate (
  $env = undef,
){

  package {
    'libsaml-spmetadata-validate-perl': ensure => installed;
    'saml-spvalidation-webservice':     ensure => installed;
  }

  # Set up samlvalidate site
  apache::site { 'samlvalidate':
    content => template('s_lemon/etc/apache2/sites-enabled/samlvalidate.erb')
  }

  # We run samlvalidate as a CGI. Since we are using Apache with a
  # MPM, we use the 'cgid' module rather than the 'cgi' module.
  apache::module { 'cgid': ensure => present }

  # Install the saml validation certificate.
  if ($env == 'prod') {
    $certname    = 'samlvalidate'
    $wallet_name = 'ssl-key/samlvalidate.stanford.edu'
  } else {
    $certname    = "samlvalidate-${env}"
    $wallet_name = "ssl-key/samlvalidate-${env}.stanford.edu"
  }
  apache::cert::comodo { $certname:
    ensure  => present,
    keyname => $wallet_name,
    symlink => false,
  }

}
