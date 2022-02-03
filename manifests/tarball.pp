define mozart::tarball($pkg_tgz=$title, $install_dir, $owner, $group) {

  # create the install directory
  unless defined(File["$install_dir"]) {
    file { "$install_dir":
      ensure  => directory,
      owner   => $user,
      group   => $group,
      mode    => "0755",
    }
  }

  # download the tgz file
  file { "$pkg_tgz":
    path    => "/tmp/$pkg_tgz",
    source  => "puppet:///modules/mozart/$pkg_tgz",
    notify  => Exec["untar $pkg_tgz"],
  }

  # untar the tarball at the desired location
  exec { "untar $pkg_tgz":
    path => ["/bin", "/usr/bin", "/usr/sbin", "/sbin"],
    command => "/bin/tar xzvf /tmp/$pkg_tgz --owner $owner --group $group -C $install_dir/",
    refreshonly => true,
    require => File["/tmp/$pkg_tgz", "$install_dir"],
  }
}
