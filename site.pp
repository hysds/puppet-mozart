if versioncmp($::puppetversion,'3.6.1') >= 0 {

  $allow_virtual_packages = hiera('allow_virtual_packages',false)

  Package {
    allow_virtual => $allow_virtual_packages,
  }
}

class yum {
  exec { "yum-update":
    command => "/bin/yum -y -q update"
  }
}

class docker {
  yumrepo { "docker-ce-stable":
    baseurl => "https://download.docker.com/linux/centos/7/$architecture/stable",
    enabled => 1,
    gpgcheck => 0
  }
}

class erlang {
  yumrepo { 'rabbitmq_erlang':
    baseurl      => 'https://packagecloud.io/rabbitmq/erlang/el/7/$basearch',
    enabled      => 1,
    gpgcheck     => 0,
  }


  yumrepo { 'rabbitmq_erlang-source':
    baseurl      => 'https://packagecloud.io/rabbitmq/erlang/el/7/SRPMS',
    enabled      => 1,
    gpgcheck     => 0,
  }
}

node 'default' {

  # define stages
  stage {
    'pre' : ;
    'post': ;
  }

  # specify stage that each class belongs to;
  # if not specified, they belong to Stage[main]
  class {
    'yum':         stage => 'pre';
    'docker':      stage => 'pre';
    'erlang':      stage => 'pre';
  }

  # stage order
  Stage['pre'] -> Stage[main] -> Stage['post']

  # modules
  include hysds_base
  include mozart

}

# set user/group in global scope so that it can be inherited
$user = 'ops'
$group = 'ops'
