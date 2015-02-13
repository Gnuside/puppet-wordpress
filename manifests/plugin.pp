define wordpress::plugin(
    $path,
    $rename_as = undef,
    $version = undef
) {
    include wordpress::params

    $plugin_name = $name

    if $rename_as == undef {
      $rename_alias = $name
    } else {
      $rename_alias = $rename_as
    }

    if $version == undef {
      $version_string = ""
    } else {
      $version_string = ".$version"
    }

    $plugin_zip_basename = "${plugin_name}${version_string}.zip"
    $plugin_src_path = "${wordpress::params::src_path}/wordpress-plugins"
    $plugin_extract_path = "${path}/wp-content/plugins"


    if ! defined(File["${plugin_src_path}"]) {
      file {"${plugin_src_path}":
        ensure => 'directory',
        owner => "www-data",
        group => "www-data",
        #mode => "0644",
        #owner => "root",
        #group => "root",
        recurse => true,
        #mode => 755,
        require => File["$wordpress::params::src_path"]
      }
    }

    if ! defined(Package["unzip"]) {
      package {"unzip":
        ensure => present,
      }
    }

    exec {"wordpress::plugin::download $title":
      user => "www-data",
      group => "www-data",
      unless => "test -f ${plugin_src_path}/${plugin_zip_basename}",
      cwd => "${plugin_src_path}",
      command => "wget -q http://downloads.wordpress.org/plugin/${plugin_zip_basename} || \
                  (rm -f ${plugin_zip_basename} && false)",
      creates => "${plugin_src_path}/${plugin_zip_basename}"
    }

    exec {"wordpress::plugin::extract $rename_alias":
      user => "www-data",
      group => "www-data",
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
