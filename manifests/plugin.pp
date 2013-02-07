define wordpress::plugin(
    $path,
    $rename_as = undef
) {
    include wordpress::params

    if $rename_as == undef {
      $rename_alias = $name
    } else {
      $rename_alias = $rename_as
    }

    $plugin_zip_basename = "$name.zip"
    $plugin_src_path = "${wordpress::params::src_path}/wordpress-plugin"
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
        ensure => present,
      }
    }

    exec {"wordpress::plugin::download $title":
      unless => "test -f ${plugin_src_path}/${plugin_zip_basename}",
      cwd => "${plugin_src_path}",
      command => "wget -q http://downloads.wordpress.org/plugin/${plugin_zip_basename}",
      creates => "${plugin_src_path}/${plugin_zip_basename}"
    }

    exec {"wordpress::plugin::extract $rename_alias":
      unless  => "test -d ${plugin_extract_path}/${rename_alias}",
      cwd     => "${plugin_extract_path}",
      command => "unzip ${plugin_src_path}/${plugin_zip_basename} -d .",
      creates => "${plugin_extract_path}/${rename_alias}",
      require => [Exec["wordpress::plugin::download $title"],
                  Package["unzip"]]
    }
}
