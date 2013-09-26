
define wordpress::data_seed(
    $domain, 
    $path,
    $seed_dir
) {
    include wordpress::params

    $archive_name = "wordpress-${version}.tar.gz"
    $archive_url = "http://wordpress.org/${archive_name}"
    $wordpress_path = "${wordpress::params::src_path}/wordpress"
    $archive_tmp = "${wordpress_path}/${archive_name}"

    if ! defined(Package["rsync"]) {
      package {"rsync":
        ensure => present,
      }
    }

    exec {"customer::load_from_data":
      require => [Wordpress::Install["${customer_username}-site"],Package["rsync"]],
      unless => "test -d ${path}/wp-content/uploads/",
      command => "rsync -avz /vagrant/${seed_dir}/ \
      ${path}/wp-content/uploads/ || \
      ( rm -fr ${path}/wp-content/uploads/ && false )",
      creates => "${path}/wp-content/uploads/"
    }
}

