
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
    $archive_dir = "${wordpress::params::src_path}/wordpress"
    $archive_tmp = "${archive_dir}/${archive_name}"

    $auth_key = sha1("auth_key$name")
    $secure_auth_key = sha1("secure_auth_key$name")
    $logged_in_key = sha1("logged_in_key$name")
    $nonce_key = sha1("nonce_key$name")
    $auth_salt = sha1("auth_salt$name")
    $secure_auth_salt = sha1("secure_auth_salt$name")
    $logged_in_salt = sha1("logged_in_salt$name")
    $nonce_salt = sha1("nonce_salt$name")

    exec { "wordpress::install::download ${version}":
      require => File["${archive_dir}"],
      unless  => "test -f ${$archive_tmp}",
      command => "wget '${archive_url}' -O '${archive_tmp}' || \
                  (rm -f '${archive_tmp}' && false)",
      user => "root",
      group => "root"
    }

    file {["${archive_dir}","${path}/wp-content","${path}/wp-content/plugins","${path}/wp-content/themes"]:
       ensure => 'directory',
       owner => "www-data",
       group => "www-data",
       #owner => "root",
       #group => "root",
       recurse => true,
       mode => 644
    }

    exec { "wordpress::install::extract ${version} to ${path}":
      unless  => "test -d '${path}/wp-admin' && test -f '${path}/.gnuside-wordpress-extracted'",
      command => "tar xaf '${archive_tmp}' && \
                  cp -fr ${archive_dir}/wordpress/* ${path} && \
                  rm -fr ${archive_dir}/wordpress && \
                  touch ${path}/.gnuside-wordpress-extracted",
      cwd     => "${archive_dir}",
      require => [
        File["${wordpress::params::src_path}"],
        Exec["wordpress::install::download ${version}"],
        File["${path}/wp-content"] # ensure that $path exists
      ]
    }

    anchor { "wordpress::install::to ${path}": 
      require => [
        Exec["wordpress::install::extract ${version} to ${path}"],
        File["${archive_dir}"],
        File["${path}/wp-content"],
        File["${path}/wp-content/plugins"]
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

