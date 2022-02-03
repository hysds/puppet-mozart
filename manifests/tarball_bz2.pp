define mozart::tarball_bz2($pkg_tbz2=$title, $install_dir, $owner, $group) {

  # create the install directory
  unless defined(File["$install_dir"]) {
    file { "$install_dir":
      ensure  => directory,
      owner   => $user,
      group   => $group,
      mode    => "0755",
    }
  }

  # download the tbz2 file
  file { "$pkg_tbz2":
    path    => "/tmp/$pkg_tbz2",
    source  => "puppet:///modules/mozart/$pkg_tbz2",
    notify  => Exec["untar $pkg_tbz2"],
  }

  # untar the tarball at the desired location
  exec { "untar $pkg_tbz2":
    path => ["/bin", "/usr/bin", "/usr/sbin", "/sbin"],
    command => "/bin/tar xjvf /tmp/$pkg_tbz2 --owner $owner --group $group -C $install_dir/",
    refreshonly => true,
    require => File["/tmp/$pkg_tbz2", "$install_dir"],
  }
}
