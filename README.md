puppet-wordpress
================

This is the puppet-wordpress module.

Usage
-----

The wordpress:install class install WordPress in the specified path.
It downloads the source code from http://wordpress.org/wordpress-${version}.tar.gz.
And extract the archive in /usr/local/src/wordpress.
A wp-config.php file is created with the specified database configuration.

    wordpress::install{"my-site":
        path              => "/var/www/my-site",
        domain            => "unused",
        database          => "db-name",
        database_username => "db-username",
        database_password => "db-password",
        database_hostname => "db-hostname", # default is '127.0.0.1'
        table_prefix      => "db-table-prefix", # default is 'wp_'
        version           => "4.0.0", # default is 'latest'
   }

WordPress is not installed if wp-config.php already exists in the target directory.

License
-------

BSD 3

Contact
-------


Support
-------

Please log tickets and issues at our [Projects site](http://projects.example.com)
