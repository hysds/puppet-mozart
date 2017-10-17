#####################################################
# mozart class
#####################################################

class mozart {

  #####################################################
  # create groups and users
  #####################################################
  
  #notify { $user: }
  if $user == undef {

    $user = 'ops'
    $group = 'ops'

    group { $group:
      ensure     => present,
    }
  

    user { $user:
      ensure     => present,
      gid        =>  $group,
      shell      => '/bin/bash',
      home       => "/home/$user",
      managehome => true,
      require    => Group[$group],
    }


    file { "/home/$user":
      ensure  => directory,
      owner   => $user,
      group   => $group,
      mode    => 0755,
      require => User[$user],
    }


    inputrc { 'root':
      home    => '/root',
    }


    inputrc { $user:
      home    => "/home/$user",
      require => User[$user],
    }


  }


  file { "/home/$user/.git_oauth_token":
    ensure  => file,
    content  => template('mozart/git_oauth_token'),
    owner   => $user,
    group   => $group,
    mode    => 0600,
    require => [
                User[$user],
               ],
  }


  file { "/home/$user/.bash_profile":
    ensure  => present,
    content => template('mozart/bash_profile'),
    owner   => $user,
    group   => $group,
    mode    => 0644,
    require => User[$user],
  }


  #####################################################
  # mozart directory
  #####################################################

  $mozart_dir = "/home/$user/mozart"


  #####################################################
  # install packages
  #####################################################

  package {
    'mailx': ensure => present;
    'httpd': ensure => present;
    'httpd-devel': ensure => present;
    'mod_ssl': ensure => present;
  }


  #####################################################
  # systemd daemon reload
  #####################################################

  exec { "daemon-reload":
    path        => ["/sbin", "/bin", "/usr/bin"],
    command     => "systemctl daemon-reload",
    refreshonly => true,
  }

  
  #####################################################
  # install oracle java and set default
  #####################################################

  $jdk_rpm_file = "jdk-8u60-linux-x64.rpm"
  $jdk_rpm_path = "/etc/puppet/modules/mozart/files/$jdk_rpm_file"
  $jdk_pkg_name = "jdk1.8.0_60"
  $java_bin_path = "/usr/java/$jdk_pkg_name/jre/bin/java"


  cat_split_file { "$jdk_rpm_file":
    install_dir => "/etc/puppet/modules/mozart/files",
    owner       =>  $user,
    group       =>  $group,
  }


  package { "$jdk_pkg_name":
    provider => rpm,
    ensure   => present,
    source   => $jdk_rpm_path,
    notify   => Exec['ldconfig'],
    require     => Cat_split_file["$jdk_rpm_file"],
  }


  update_alternatives { 'java':
    path     => $java_bin_path,
    require  => [
                 Package[$jdk_pkg_name],
                 Exec['ldconfig']
                ],
  }


  #####################################################
  # install install_hysds.sh script and other config
  # files in ops home
  #####################################################

  file { "/home/$user/install_hysds.sh":
    ensure  => present,
    content => template('mozart/install_hysds.sh'),
    owner   => $user,
    group   => $group,
    mode    => 0755,
    require => User[$user],
  }


  file { ["$mozart_dir",
          "$mozart_dir/bin",
          "$mozart_dir/src",
          "$mozart_dir/etc"]:
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => 0755,
    require => User[$user],
  }


  file { "$mozart_dir/bin/mozartd":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => 0755,
    content => template('mozart/mozartd'),
    require => File["$mozart_dir/bin"],
  }


  file { "$mozart_dir/bin/start_mozart":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => 0755,
    content => template('mozart/start_mozart'),
    require => File["$mozart_dir/bin"],
  }
 

  file { "$mozart_dir/bin/stop_mozart":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => 0755,
    content => template('mozart/stop_mozart'),
    require => File["$mozart_dir/bin"],
  }


  cat_split_file { "logstash-1.5.5.tar.gz":
    install_dir => "/etc/puppet/modules/mozart/files",
    owner       =>  $user,
    group       =>  $group,
  }


  tarball { "logstash-1.5.5.tar.gz":
    install_dir => "/home/$user",
    owner => $user,
    group => $group,
    require => [
                User[$user],
                Cat_split_file["logstash-1.5.5.tar.gz"],
               ]
  }


  file { "/home/$user/logstash":
    ensure => 'link',
    target => "/home/$user/logstash-1.5.5",
    owner => $user,
    group => $group,
    require => Tarball['logstash-1.5.5.tar.gz'],
  }


  tarball { "kibana-3.1.2.tar.gz":
    install_dir => "/var/www/html",
    owner => 'root',
    group => 'root',
    require => [
                User[$user],
                Package['httpd'],
               ],
  }

 
  file { "/var/www/html/metrics":
    ensure => 'link',
    target => "/var/www/html/kibana-3.1.2",
    owner => 'root',
    group => 'root',
    require => Tarball['kibana-3.1.2.tar.gz'],
  }


  #####################################################
  # write rc.local to startup & shutdown mozart
  #####################################################

  file { '/etc/rc.d/rc.local':
    ensure  => file,
    content  => template('mozart/rc.local'),
    mode    => 0755,
  }


  #####################################################
  # secure and start httpd
  #####################################################

  file { "/etc/httpd/conf.d/autoindex.conf":
    ensure  => present,
    content => template('mozart/autoindex.conf'),
    mode    => 0644,
    require => Package['httpd'],
  }


  file { "/etc/httpd/conf.d/welcome.conf":
    ensure  => present,
    content => template('mozart/welcome.conf'),
    mode    => 0644,
    require => Package['httpd'],
  }

 
  file { "/etc/httpd/conf.d/ssl.conf":
    ensure  => present,
    content => template('mozart/ssl.conf'),
    mode    => 0644,
    require => Package['httpd'],
  }

 
  file { '/var/www/html/index.html':
    ensure  => file,
    content => template('mozart/index.html'),
    mode    => 0644,
    require => Package['httpd'],
  }


  #####################################################
  # disable requiretty so supervisord can run sudo
  #####################################################

  augeas { "turn_off_sudo_requiretty":
    changes => [
      'set /files/etc/sudoers/Defaults[*]/requiretty/negate ""',
    ]
  }
}
