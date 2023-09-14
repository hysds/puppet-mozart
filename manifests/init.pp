#####################################################
# mozart class
#####################################################

class mozart inherits scientific_python {

  #####################################################
  # add swap file 
  #####################################################

  #swap { '/mnt/swapfile':
  #  ensure   => present,
  #}


  #####################################################
  # copy user files
  #####################################################

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
  $jdk_rpm_path = "/etc/puppet/modules/mozart/files/$jdk_rpm_file"
  $jdk_pkg_name = "jdk1.8.x86_64"
  $java_bin_path = "/usr/java/jdk1.8.0_241-amd64/jre/bin/java"


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
  # get integer memory size in MB
  #####################################################

  if '.' in $::memorysize_mb {
    $ms = split("$::memorysize_mb", '[.]')
    $msize_mb = $ms[0]
  }
  else {
    $msize_mb = $::memorysize_mb
  }


  #####################################################
  # install elasticsearch
  #####################################################

  $es_heap_size = $msize_mb / 2
  $es_rpm_file = "elasticsearch-7.9.3-x86_64.rpm"
  $es_rpm_path = "/etc/puppet/modules/mozart/files/$es_rpm_file"


  cat_split_file { "$es_rpm_file":
    install_dir => "/etc/puppet/modules/mozart/files",
    owner       =>  $user,
    group       =>  $group,
  }


  package { 'elasticsearch':
    provider => rpm,
    ensure   => present,
    source   => $es_rpm_path,
    require  => [
                  Cat_split_file["$es_rpm_file"],
                  Exec['set-java'],
                ],
  }


  file { '/etc/sysconfig/elasticsearch':
    ensure       => file,
    content      => template('mozart/elasticsearch'),
    mode         => 0644,
    require      => Package['elasticsearch'],
  }


  file { '/etc/elasticsearch/elasticsearch.yml':
    ensure       => file,
    content      => template('mozart/elasticsearch.yml'),
    mode         => 0644,
    require      => Package['elasticsearch'],
  }


  file { '/etc/elasticsearch/log4j2.properties':
    ensure       => file,
    content      => template('mozart/log4j2.properties'),
    mode         => 0644,
    require      => Package['elasticsearch'],
  }


  file { '/usr/lib/systemd/system/elasticsearch.service':
    ensure       => file,
    content      => template('mozart/elasticsearch.service'),
    mode         => 0644,
    require      => Package['elasticsearch'],
  }


  service { 'elasticsearch':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => [
                   File['/etc/sysconfig/elasticsearch'],
                   File['/etc/elasticsearch/elasticsearch.yml'],
                   File['/etc/elasticsearch/log4j2.properties'],
                   File['/usr/lib/systemd/system/elasticsearch.service'],
                   Exec['daemon-reload'],
                  ],
  }


  $cerebro_rpm_file = "cerebro-0.8.5-1.noarch.rpm"
  $cerebro_rpm_path = "/etc/puppet/modules/mozart/files/$cerebro_rpm_file"


  cat_split_file { "$cerebro_rpm_file":
    install_dir => "/etc/puppet/modules/mozart/files",
    owner       =>  $user,
    group       =>  $group,
  }


  package { 'cerebro':
    provider => rpm,
    ensure   => present,
    source   => $cerebro_rpm_path,
    require  => [
                  Cat_split_file["$cerebro_rpm_file"],
                  Service['elasticsearch'],
                  Exec['set-java'],
                ],
  }


  file { '/usr/lib/systemd/system/cerebro.service':
    ensure       => file,
    content      => template('mozart/cerebro.service'),
    mode         => 0644,
    require      => Package['cerebro'],
  }


  service { 'cerebro':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => [
                   Package['cerebro'],
                   Exec['daemon-reload'],
                  ],
    subscribe  => File['/usr/lib/systemd/system/cerebro.service'],
  }


  #####################################################
  # disable transparent hugepages for redis
  #####################################################

  file { "/etc/tuned/no-thp":
    ensure  => directory,
    mode    => 0755,
  }


  file { "/etc/tuned/no-thp/tuned.conf":
    ensure  => present,
    content => template('mozart/tuned.conf'),
    mode    => 0644,
    require => File["/etc/tuned/no-thp"],
  }

  
  exec { "no-thp":
    unless  => "grep -q -e '^no-thp$' /etc/tuned/active_profile",
    path    => ["/sbin", "/bin", "/usr/bin"],
    command => "tuned-adm profile no-thp",
    require => File["/etc/tuned/no-thp/tuned.conf"],
  }


  #####################################################
  # tune kernel for high performance
  #####################################################

  file { "/usr/lib/sysctl.d":
    ensure  => directory,
    mode    => 0755,
  }


  file { "/usr/lib/sysctl.d/mozart.conf":
    ensure  => present,
    content => template('mozart/mozart.conf'),
    mode    => 0644,
    require => File["/usr/lib/sysctl.d"],
  }

  
  exec { "sysctl-system":
    path    => ["/sbin", "/bin", "/usr/bin"],
    command => "/sbin/sysctl --system",
    require => File["/usr/lib/sysctl.d/mozart.conf"],
  }


  #####################################################
  # install redis
  #####################################################

  package { "redis":
    ensure   => present,
    notify   => Exec['ldconfig'],
    require => [
                Exec["no-thp"],
                Exec["sysctl-system"],
               ],
  }


  file { '/etc/redis.conf':
    ensure       => file,
    content      => template('mozart/redis.conf'),
    mode         => 0644,
    require      => Package['redis'],
  }


  file { ["/etc/systemd/system/redis.service.d",
         "/etc/systemd/system/redis-sentinel.service.d"]:
    ensure  => directory,
    mode    => 0755,
  }


  file { "/etc/systemd/system/redis.service.d/limit.conf":
    ensure  => present,
    content => template('mozart/redis_service.conf'),
    mode    => 0644,
    require => File["/etc/systemd/system/redis.service.d"],
  }

  
  file { "/etc/systemd/system/redis-sentinel.service.d/limit.conf":
    ensure  => present,
    content => template('mozart/redis_service.conf'),
    mode    => 0644,
    require => File["/etc/systemd/system/redis-sentinel.service.d"],
  }

  
  service { 'redis':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => [
                   File['/etc/redis.conf'],
                   File['/etc/systemd/system/redis.service.d/limit.conf'],
                   File['/etc/systemd/system/redis-sentinel.service.d/limit.conf'],
                   Exec['daemon-reload'],
                  ],
  }


  #####################################################
  # install rabbitmq
  #####################################################

  $rmq_rpm_pkg = "/etc/puppet/modules/mozart/files/rabbitmq-server-3.8.2-1.el7.noarch.rpm"
  $rmq_pkg_name = "rabbitmq-server-3.8.2-1.el7"


  exec { "$rmq_pkg_name":
    path    => ["/sbin", "/bin", "/usr/bin"],
    unless  => "rpm -q $rmq_pkg_name",
    command => "yum install -y $rmq_rpm_pkg",
    notify  => Exec['ldconfig'],
  }


  file { '/etc/rabbitmq/rabbitmq.config':
    ensure  => file,
    content  => template('mozart/rabbitmq.config'),
    mode    => 0644,
    require => Exec[$rmq_pkg_name],
  }


  file { '/etc/rabbitmq/rabbitmq-env.conf':
    ensure  => file,
    content  => template('mozart/rabbitmq-env.conf'),
    mode    => 0644,
    require => Exec[$rmq_pkg_name],
  }


  file { '/etc/default/rabbitmq-server':
    ensure  => file,
    content  => template('mozart/rabbitmq-server'),
    mode    => 0644,
    require => Exec[$rmq_pkg_name],
  }


  file { "/etc/systemd/system/rabbitmq-server.service.d":
    ensure  => directory,
    mode    => 0755,
  }


  file { "/etc/systemd/system/rabbitmq-server.service.d/limits.conf":
    ensure  => present,
    content => template('mozart/limits.conf'),
    mode    => 0644,
    require => File["/etc/systemd/system/rabbitmq-server.service.d"],
  }

  
  service { 'rabbitmq-server':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => [
                   File['/etc/rabbitmq/rabbitmq.config'],
                   File['/etc/default/rabbitmq-server'],
                   File['/etc/systemd/system/rabbitmq-server.service.d/limits.conf'],
                   Exec['daemon-reload'],
                  ],
  }


  exec { "rabbitmq_management":
    environment => "HOME=/root",
    path        => ["/sbin", "/bin", "/usr/bin"],
    unless      => "rabbitmq-plugins list -E -m | grep -q -e '^rabbitmq_management$'",
    command     => "rabbitmq-plugins enable rabbitmq_management",
    require     => Service['rabbitmq-server'],
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


  cat_split_file { "logstash-oss-7.16.3.tar.gz":
    install_dir => "/etc/puppet/modules/mozart/files",
    owner       =>  $user,
    group       =>  $group,
  }


  tarball { "logstash-oss-7.16.3.tar.gz":
    install_dir => "/home/$user",
    owner => $user,
    group => $group,
    require => [
                User[$user],
                Cat_split_file["logstash-oss-7.16.3.tar.gz"],
               ]
  }


  file { "/home/$user/logstash":
    ensure => 'link',
    target => "/home/$user/logstash-oss-7.16.3",
    owner => $user,
    group => $group,
    require => Tarball['logstash-oss-7.16.3.tar.gz'],
  }


  cat_split_file { "kibana-7.9.3-linux-x86_64.tar.gz":
    install_dir => "/etc/puppet/modules/mozart/files",
    owner       =>  $user,
    group       =>  $group,
  }


  tarball { "kibana-7.9.3-linux-x86_64.tar.gz":
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
    target => "/var/www/html/kibana-7.9.3",
    owner => 'root',
    group => 'root',
    require => Tarball['kibana-7.9.3-linux-x86_64.tar.gz'],
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


  service { 'httpd':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => [
                   File['/var/www/html/metrics'],
                   File['/etc/httpd/conf.d/autoindex.conf'],
                   File['/etc/httpd/conf.d/welcome.conf'],
                   File['/etc/httpd/conf.d/ssl.conf'],
                   File['/var/www/html/index.html'],
                   Exec['daemon-reload'],
                  ],
  }


  #####################################################
  # firewalld config
  #####################################################

  firewalld::zone { 'public':
    services => [ "ssh", "dhcpv6-client", "http", "https" ],
    ports => [
      {
        # Cerebro (ES web admin tool)
        port     => "9000",
        protocol => "tcp",
      },
      {
        # ElasticSearch
        port     => "9200",
        protocol => "tcp",
      },
      {
        # ElasticSearch
        port     => "9300",
        protocol => "tcp",
      },
      {
        # ElasticSearch
        port     => "9300",
        protocol => "udp",
      },
      {
        # Redis
        port     => "6379",
        protocol => "tcp",
      },
      {
        # RabbitMQ
        port     => "5672",
        protocol => "tcp",
      },
      {
        # RabbitMQ admin
        port     => "15672",
        protocol => "tcp",
      },
      {
        # Mozart Job Management
        port     => "8888",
        protocol => "tcp",
      },
      {
        # Figaro UI
        port     => "8898",
        protocol => "tcp",
      },
      {
        # Flower
        port     => "5555",
        protocol => "tcp",
      },
    ]
  }


  #firewalld::service { 'dummy':
  #  description	=> 'My dummy service',
  #  ports       => [{port => '1234', protocol => 'tcp',},],
  #  modules     => ['some_module_to_load'],
  #  destination	=> {ipv4 => '224.0.0.251', ipv6 => 'ff02::fb'},
  #}


}
