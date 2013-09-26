define wordpress::url_rewrite(
    $path
) {
    include wordpress::params

    file { "${path}/.htaccess":
        content => template("wordpress/dot.htaccess.erb"),
        owner => "www-data",
        group => "www-data",
        mode => "0644",
        require => Anchor["wordpress::install::to ${path}"]
    }
}
