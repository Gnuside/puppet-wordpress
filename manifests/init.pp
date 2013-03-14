# == Class: puppet-wordpress
#
# Full description of class puppet-wordpress here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if it
#   has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should not be used in preference to class parameters  as of
#   Puppet 2.6.)
#
# === Examples
#
#  class { puppet-wordpress:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ]
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2013 Your name here, unless otherwise noted.
#
class wordpress {
    #   include wordpress::fetch, wordpress::build, wordpress::install, wordpress:service;
}

class wordpress::params {
  $src_path = "/usr/local/src"

  file {"${src_path}":
    ensure => 'directory',
    owner => "root",
    group => "root",
    recurse => true,
    mode => 755
  }
}


    if $rename_as == undef {
      $rename_alias = $name
    } else {
      $rename_alias = $rename_as
    }

    $plugin_zip_basename = "$name.zip"
    $plugin_src_path = "${wordpress::params::src_path}/wordpress-plugins"
    $plugin_extract_path = "${path}/wp-content/plugins"

    if ! defined(File["${plugin_src_path}"]) {
      file {"${plugin_src_path}":
        ensure => 'directory',
        owner => "root",
        group => "root",
        recurse => true,
        mode => 755,
        require => File["$wordpress::params::src_path"]
      }
    }

    if ! defined(Package["unzip"]) {
      package {"unzip":
        ensure => installed
      }
    }

    exec {"wordpress::plugin::download $title":
      unless => "test -f ${plugin_src_path}/${plugin_zip_basename}",
      cwd => "${plugin_src_path}",
      command => "wget -q http://downloads.wordpress.org/plugin/${plugin_zip_basename} || \
                  (rm -f ${plugin_zip_basename} && false)",
      creates => "${plugin_src_path}/${plugin_zip_basename}"
    }

    exec {"wordpress::plugin::extract $rename_alias":
      unless  => "test -d ${plugin_extract_path}/${rename_alias}",
      cwd     => "${plugin_extract_path}",
      command => "unzip ${plugin_src_path}/${plugin_zip_basename} -d .",
      creates => "${plugin_extract_path}/${rename_alias}",
      require => [Exec["wordpress::plugin::download $title"],
                  Package["unzip"],
                  Anchor["wordpress::install::to ${path}"]
                ]
    }

}

define wordpress::install(
    $domain, 
    $path, 
    $database, 
    $database_username, 
    $database_password,
    $version = 'latest'
) {
    include wordpress::params

    $archive_name = "wordpress-${version}.tar.gz"
    $archive_url = "http://wordpress.org/${archive_name}"
    $wordpress_path = "${wordpress::params::src_path}/wordpress"
    $archive_tmp = "${wordpress_path}/${archive_name}"

    $auth_key = sha1("auth_key$name")
    $secure_auth_key = sha1("secure_auth_key$name")
    $logged_in_key = sha1("logged_in_key$name")
    $nonce_key = sha1("nonce_key$name")
    $auth_salt = sha1("auth_salt$name")
    $secure_auth_salt = sha1("secure_auth_salt$name")
    $logged_in_salt = sha1("logged_in_salt$name")
    $nonce_salt = sha1("nonce_salt$name")

    exec { "wordpress::install::download ${version}":
      require => File["${wordpress_path}"],
      unless  => "test -f ${archive_tmp}",
      command => "wget '${archive_url}' -O '${archive_tmp}' || \
                  (rm '${archive_tmp}' && false)"
    }

    file {"${wordpress_path}":
       ensure => 'directory',
       owner => "root",
       group => "root",
       recurse => true,
       mode => 755
    }

    exec { "wordpress-install-extract-${version}-to-${path}":
      unless  => "test -d '${path}'",
      command => "tar xaf '${archive_tmp}' ; \
        mkdir -p `dirname '${path}'` ; \
        mv wordpress '${path}'",
      cwd     => "/${src_path}",
      require => [
        File["${src_path}"],
        Exec["wordpress::install::download ${version}"]
      ]
    }

    anchor { "wordpress::install::to ${path}": 
      require => Exec["wordpress-install-extract-${version}-to-${path}"]
    }

    #if ($version == 'latest') {
    #  exec { "wordpress-remove-download-${version}":
    #    unless  => "test ! -f ${$archive_tmp}",
    #    command => "rm -f '${archive_tmp}'",
    #    require => Exec["wordpress-install-extract-${version}-to-${path}"]
    #  }
    #}

    file { "${path}/wp-config.php":
        content => template("wordpress/wp-config.php.erb"),
        owner => "www-data",
        group => "www-data",
        mode => "0644",
        require => Exec["wordpress-install-extract-${version}-to-${path}"]
    }

    #    file { "$path":
    #	ensure    => "directory",
    #	source   => "puppet://puppet.example.com/dist/apps/wordpress/wordpress",
    #	recurse => "true",
    #	force  => true,
    #	mode  => "0644",
    #    }
}

class wordpress::service {
    include wordpress::params
}

