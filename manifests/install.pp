
define wordpress::install(
    $domain, 
    $path, 
    $database, 
    $database_username, 
    $database_password,
    $database_hostname = '127.0.0.1',
    $version = 'latest',
    $table_prefix = 'wp_'
) {
    include wordpress::params

    $archive_name = "wordpress-${version}.tar.gz"
    $archive_url  = "http://wordpress.org/${archive_name}"
    $archive_dir  = "${wordpress::params::src_path}/wordpress"
    $archive_tmp  = "${archive_dir}/${archive_name}"

    $auth_key         = sha1("auth_key$name")
    $secure_auth_key  = sha1("secure_auth_key$name")
    $logged_in_key    = sha1("logged_in_key$name")
    $nonce_key        = sha1("nonce_key$name")
    $auth_salt        = sha1("auth_salt$name")
    $secure_auth_salt = sha1("secure_auth_salt$name")
    $logged_in_salt   = sha1("logged_in_salt$name")
    $nonce_salt       = sha1("nonce_salt$name")

    exec { "wordpress::install::download ${version} for ${path}":
      require => File["${archive_dir}"],
      unless  => "test -f ${$archive_tmp} || \
                  test -f '${path}/wp-config.php'",
      command => "wget '${archive_url}' -O '${archive_tmp}' || \
                  (rm -f '${archive_tmp}' && false)",
      user    => "root",
      group   => "root"
    }

    file { "${path}":
      ensure  => 'directory',
      owner   => "www-data",
      group   => "www-data",
      recurse => true,
      mode    => 644
    }

    if ! defined(File["${archive_dir}"]) {
      file { "${archive_dir}":
        ensure  => 'directory',
        owner   => "www-data",
        group   => "www-data",
        recurse => true,
        mode    => 644,
      }
    }

    file {["${path}/wp-content","${path}/wp-content/plugins"]:
      ensure  => 'directory',
      owner   => "www-data",
      group   => "www-data",
      recurse => true,
      mode    => 644,
      require => File["${path}"]
    }

    exec { "wordpress::install::extract ${version} to ${path}":
      unless  => "test -d '${path}/wp-admin' || \
                  test -f '${path}/wp-config.php'",
      command => "tar xaf '${archive_tmp}' && \
                  cp -fr ${archive_dir}/wordpress/* ${path} && \
                  rm -fr ${archive_dir}/wordpress && \
                  chown -R www-data:www-data ${path}",
      cwd     => "${archive_dir}",
      require => [
        File["${wordpress::params::src_path}"],
        Exec["wordpress::install::download ${version} for ${path}"],
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

    file { "${path}/wp-config-development.php":
      content => template("wordpress/wp-config.php.erb"),
      owner   => "www-data",
      group   => "www-data",
      mode    => "0644",
      require => Exec["wordpress::install::extract ${version} to ${path}"]
    }

    exec { "wordpress::install::copy_config in ${path}":
      unless  => "test -f ${path}/wp-config.php",
      command => "cp ${path}/wp-config-development.php ${path}/wp-config.php",
      cwd     => "${path}",
      require => File["${path}/wp-config-development.php"]
    }
}

