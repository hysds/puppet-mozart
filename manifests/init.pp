#####################################################
# mozart class
#####################################################

class mozart inherits hysds_base {

  #####################################################
  # copy user files
  #####################################################
  
  file { "/$user/.bash_profile":
    ensure  => present,
    content => template('mozart/bash_profile'),
    owner   => $user,
    group   => $group,
    mode    => "0644",
    require => User[$user],
  }


  #####################################################
  # mozart directory
  #####################################################

  $mozart_dir = "/$user/mozart"


  #####################################################
  # install packages
  #####################################################

  package {
    'mailx': ensure => present;
    'httpd': ensure => present;
    'mod_ssl': ensure => present;
    'nodejs': ensure => present;
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

  $jdk_rpm_file = "jdk-8u241-linux-x64.rpm"
  $jdk_rpm_path = "/etc/puppetlabs/code/modules/mozart/files/$jdk_rpm_file"
  $jdk_pkg_name = "jdk1.8.x86_64"
  $java_bin_path = "/usr/java/jdk1.8.0_241-amd64/jre/bin/java"


  mozart::cat_split_file { "$jdk_rpm_file":
    install_dir => "/etc/puppetlabs/code/modules/mozart/files",
    owner       =>  $user,
    group       =>  $group,
  }


  package { "$jdk_pkg_name":
    provider => rpm,
    ensure   => present,
    source   => $jdk_rpm_path,
    notify   => Exec['ldconfig'],
    require     => Mozart::Cat_split_file["$jdk_rpm_file"],
  }


  mozart::update_alternatives { 'java':
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

  file { "/$user/install_hysds.sh":
    ensure  => present,
    content => template('mozart/install_hysds.sh'),
    owner   => $user,
    group   => $group,
    mode    => "0755",
    require => User[$user],
  }


  file { ["$mozart_dir",
          "$mozart_dir/bin",
          "$mozart_dir/src",
          "$mozart_dir/etc"]:
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => "0755",
    require => User[$user],
  }


  file { "$mozart_dir/bin/mozartd":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => "0755",
    content => template('mozart/mozartd'),
    require => File["$mozart_dir/bin"],
  }


  file { "$mozart_dir/bin/start_mozart":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => "0755",
    content => template('mozart/start_mozart'),
    require => File["$mozart_dir/bin"],
  }
 

  file { "$mozart_dir/bin/stop_mozart":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => "0755",
    content => template('mozart/stop_mozart'),
    require => File["$mozart_dir/bin"],
  }


  mozart::cat_split_file { "logstash-7.9.3.tar.gz":
    install_dir => "/etc/puppetlabs/code/modules/mozart/files",
    owner       =>  $user,
    group       =>  $group,
  }


  mozart::tarball { "logstash-7.9.3.tar.gz":
    install_dir => "/$user",
    owner => $user,
    group => $group,
    require => [
                User[$user],
                Mozart::Cat_split_file["logstash-7.9.3.tar.gz"],
               ]
  }


  file { "/$user/logstash":
    ensure => 'link',
    target => "/$user/logstash-7.9.3",
    owner => $user,
    group => $group,
    require => Mozart::Tarball['logstash-7.9.3.tar.gz'],
  }


  #####################################################
  # write rc.local to startup & shutdown mozart
  #####################################################

  file { '/etc/rc.d/rc.local':
    ensure  => file,
    content  => template('mozart/rc.local'),
    mode    => "0755",
  }


  #####################################################
  # generate ssl certs: problem with mod_ssl per
  # https://community.letsencrypt.org/t/localhost-crt-does-not-exist-or-is-empty/103979/4
  #####################################################

  exec { "httpd-ssl-gencerts":
    command => "/usr/libexec/httpd-ssl-gencerts",
    require => Package["mod_ssl"],
  }


  #####################################################
  # secure and start httpd
  #####################################################

  file { "/etc/httpd/conf.d/autoindex.conf":
    ensure  => present,
    content => template('mozart/autoindex.conf'),
    mode    => "0644",
    require => Package['httpd'],
  }


  file { "/etc/httpd/conf.d/welcome.conf":
    ensure  => present,
    content => template('mozart/welcome.conf'),
    mode    => "0644",
    require => Package['httpd'],
  }

 
  file { "/etc/httpd/conf.d/ssl.conf":
    ensure  => present,
    content => template('mozart/ssl.conf'),
    mode    => "0644",
    require => Package['httpd'],
  }

 
  file { '/var/www/html/index.html':
    ensure  => file,
    content => template('mozart/index.html'),
    mode    => "0644",
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
