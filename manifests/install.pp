
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
      unless  => "test -f ${$archive_tmp}",
      command => "wget '${archive_url}' -O '${archive_tmp}' || \
                  (rm -f '${archive_tmp}' && false)",
      user => "root",
      group => "root"
    }

    file {["${wordpress_path}","${wordpress_path}/wp-content","${wordpress_path}/wp-content/plugins"]:
       ensure => 'directory',
       owner => "www-data",
       group => "www-data",
       #owner => "root",
       #group => "root",
       recurse => true,
       mode => 644
    }

    exec { "wordpress::install::extract ${version} to ${path}":
      unless  => "test -d '${path}'",
      command => "tar xaf '${archive_tmp}' ; \
        mkdir -p `dirname '${path}'` ; \
        mv wordpress '${path}'",
      cwd     => "/${wordpress::params::src_path}",
      require => [
        File["${wordpress::params::src_path}"],
        Exec["wordpress::install::download ${version}"]
      ]
    }

    anchor { "wordpress::install::to ${path}": 
      require => [
        Exec["wordpress::install::extract ${version} to ${path}"],
        File["${wordpress_path}"],
        File["${wordpress_path}/wp-content"],
        File["${wordpress_path}/wp-content/plugins"]
      ]
    }

    file { "${path}/wp-config.php":
        content => template("wordpress/wp-config.php.erb"),
        owner => "www-data",
        group => "www-data",
        mode => "0644",
        require => Exec["wordpress::install::extract ${version} to ${path}"]
    }

}

