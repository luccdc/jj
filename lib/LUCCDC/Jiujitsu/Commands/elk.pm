package LUCCDC::Jiujitsu::Commands::elk;
use strictures 2;

use Carp;
use File::Path qw(make_path);
use IPC::Open2;
use POSIX ":sys_wait_h";

use LUCCDC::Jiujitsu::Util::Logging          qw(message error warning header);
use LUCCDC::Jiujitsu::Util::Linux::PerDistro qw(platform);
use LUCCDC::Jiujitsu::Util::Arguments        qw(&parser);
use LUCCDC::Jiujitsu::Util::DownloadContainer
  qw(&create_container &run_closure &destroy_container);

# Set aside string so that I can use the literal
# ${path.config} in heredoc strings
my $path_config = '${path.config}';

my $elastic_password = "";

sub get_elastic_password {
    if ( $elastic_password eq "" ) {
        `stty -echo`;
        print "Enter the password for the elastic user: ";
        $elastic_password = <STDIN>;
        `stty echo`;
        chomp $elastic_password;
    }
    return $elastic_password;
}

my @options = (
    {
        name => 'elastic_version',
        flag => '--esver|-V',
        val  => '9.2.0',
        type => 'string'
    },
    {
        name => 'download_url',
        flag => '--download-url',
        val  => 'https://artifacts.elastic.co/downloads',
        type => 'string'
    },
    {
        name => 'beats_download_url',
        flag => '--beats-download-url',
        val  => 'https://artifacts.elastic.co/downloads/beats',
        type => 'string'
    },
    {
        name => 'elasticsearch_share_directory',
        flag => '--es-share-dir|-S',
        val  => '/opt/es',
        type => 'string'
    },
    {
        name => 'elk_ip',
        flag => '--elk-ip|-i',
        val  => '127.0.0.1',
        type => 'string'
    },
    {
        name => 'elk_share_port',
        flag => '--elk-share-port|-p',
        val  => 8080,
        type => 'number'
    },
    {
        name => 'download_shell',
        flag => '--use-download-shell|-d',
        val  => 0,
        type => 'flag'
    },
    {
        name => 'sneaky_ip',
        flag => '--sneaky-ip|-I',
        val  => '',
        type => 'string'
    },
);

my %subcommands = (
    '--help'           => \&help,
    '-h'               => \&help,
    'help'             => \&help,
    'install'          => \&install,
    'in'               => \&install,
    'setupzram'        => \&setup_zram,
    'zr'               => \&setup_zram,
    'downloadpackages' => \&download_packages,
    'dpkg'             => \&download_packages,
    'installpackages'  => \&install_packages,
    'ipkg'             => \&install_packages,
    'setupelastic'     => \&setup_elasticsearch,
    'es'               => \&setup_elasticsearch,
    'setupkibana'      => \&setup_kibana,
    'ki'               => \&setup_kibana,
    'setuplogstash'    => \&setup_logstash,
    'lo'               => \&setup_logstash,
    'setupauditbeat'   => \&setup_auditbeat,
    'ab'               => \&setup_auditbeat,
    'setuppacketbeat'  => \&setup_packetbeat,
    'pb'               => \&setup_packetbeat,
    'setupfilebeat'    => \&setup_filebeat,
    'fb'               => \&setup_filebeat,
    'beats'            => \&install_beats,
    'installbeats'     => \&install_beats
);

my %helpcommands = (
    '--help' => \&help,
    '-h'     => \&help
);

my $toplevel_parser = parser( \@options, \%subcommands );
my $sub_parser      = parser( \@options, \%helpcommands );

my $AUDITBEAT_BASE_CONFIG = <<'EOD';
auditbeat.modules:
- module: auditd
  audit_rules: |
    # Executions
    -a always,exit -F arch=b64 -S execve,execveat -k exec
    -a always,exit -F arch=b64 -S clone,clone3 -k clones

    # Identity changes
    -w /etc/group -p wa -k identity
    -w /etc/passwd -p wa -k identity
    -w /etc/gshadow -p wa -k identity
    -w /etc/shadow -p wa -k identity

    # Unauthorized access attempts/enumeration
    -a always,exit -F arch=b64 -S open,creat,truncat,ftruncate,openat,open_by_handle_at -F exit=-EACCESS -k access
    -a always,exit -F arch=b64 -S open,creat,truncat,ftruncate,openat,open_by_handle_at -F exit=-EPERM -k access
    -a always,exit -F arch=b64 -S geteuid,getuid,getegid,getgid -k potential_enum

    # Networking info
    -a always,exit -F arch=b64 -S socket -k sockets
    -a always,exit -F arch=b64 -S socket -F a0=17 -F a1=3 -k raw_sockets

    # Process injection
    -a always,exit -F arch=b64 -S ptrace -k ptrace

- module: file_integrity
  paths:
  - /bin
  - /usr/bin
  - /sbin
  - /usr/sbin
  - /etc

- module: system
  datasets:
  - host
  - login
  - process
  - socket
  - user
  state.period: 12h
  user.detect_password_changes: true
  login.wtmp_file_pattern: /var/log/wtmp*
  login.btmp_file_pattern: /var/log/btmp*

setup.template.settings.index.number_of_shards: 1

processors:
  - add_host_metadata: ~
  - add_docker_metadata: ~

EOD

my $PACKETBEAT_BASE_CONFIG = <<'EOD';
packetbeat.interfaces.device: any
packetbeat.interfaces.poll_default_route: 1m
packetbeat.interfaces.internal_networks:
  - private
packetbeat.flows:
  timeout: 30s
  period: 10s
packetbeat.protocols:
- type: icmp
  enabled: true
- type: amqp
  ports: [5672]
- type: cassandra
  ports: [9042]
- type: dhcpv4
  ports: [67, 68]
- type: dns
  ports: [53]
- type: http
  ports: [80, 8080, 8000, 5000, 8002]
- type: memcache
  ports: [11211]
- type: mysql
  ports: [3306, 3307]
- type: pgsql
  ports: [5432]
- type: redis
  ports: [6379]
- type: thrift
  ports: [9090]
- type: mongodb
  ports: [27017]
- type: nfs
  ports: [2049]
- type: tls
  ports:
    - 8443
- type: sip
  ports: [5060]

setup.template.settings.index.number_of_shards: 1

processors:
  - if.contains.tags: forwarded
    then:
      - drop_fields:
          fields: [host]
    else:
      - add_host_metadata: ~
  - add_cloud_metadata: ~
  - add_docker_metadata: ~
  - detect_mime_type:
      field: http.request.body.content
      target: http.request.mime_type
  - detect_mime_type:
      field: http.response.body.content
      target: http.response.mime_type

EOD

# This config is special; it will be used as is for both local beats installation and
# the central log server installation. It is intended to be injected into a file with
# text coming after it in an ambiguous format; on the central ELK server, it allows for
# injecting configuration to accept Cisco, Netflow, and Palo Alto logs, but on
# endpoints it allows for specifying other modules that aren't those 3
my $FILEBEAT_BASE_CONFIG = <<'EOD';
filebeat.inputs:
- type: udp
  max_message_size: 10KiB
  host: "0.0.0.0:514"
  processors:
    - syslog:
        field: message

processors:
  - add_host_metadata:
      when.not.contains.tags: forwarded
  - add_docker_metadata: ~

setup.template.settings.index.number_of_shards: 1

filebeat.modules:
  - module: system
    syslog:
      enabled: true
    auth:
      enabled: true
EOD

sub run {
    my @cmdline = @_;

    die "You must be root to install ELK" unless $> == 0;
    die "A hostname must be set!"
      if `hostnamectl` =~ qr/Static\+hostname:\s+\(unset\)/xms;

    $toplevel_parser->(@cmdline);

    exit;
}

sub help {
    my ($progname) = $0 =~ m{([^\/]+)$}xms;

    print <<"END_HELP";
Installs and configures ELK or ELK dependent endpoints (beats)

Usage:
    $progname elk install                                    # Installs an ELK stack
    $progname elk install -d -I 10.0.2.16                    # Installs an ELK stack using the download shell and a sneaky IP
    $progname elk beats -i 192.168.128.53                    # Installs beats to point to the ELK stack, downloading resources from the ELK share
    $progname elk beats -i 192.168.128.53 -P 8000            # Installs beats, replacing the share port with 8000 instead of 8080
    $progname elk beats -i 192.168.128.53 -d -I 10.0.2.17    # Installs beats using the download shell and sneaky IP

Common subcommand options:
    -V, --esver=VERSION                                                The version to use for ELK and beats packages
    --download-url=https://artifacts.elastic.co/downloads              The URL to download ELK packages from
    --beats-download-url=https://artifacts.elastic.co/downloads/beats  The URL to download ELK packages from
    -S, --es-share-dir=/opt/es                                         Where to store downloaded packages for redistribution, and where to place the CA certificate
	  -i, --elk-ip=IP                                                    The IP address of the ELK server
	  -P, --elk-share-port=IP                                            The port of the share that a Python web server should be running from
	  -d, --use-download-shell                                           Use the download shell when downloading packages
	  -I, --sneaky-ip=IP                                                 Sneaky IP to use when making use of the download shell
	  -h, --help                                                         Print this help message

Subcommands:
    in, install:               Run through the full set up ELK setup commands; equivalent to zr, dpkg, ipkg, es, ki, lo, ab, pb, and fb
    zr, setupzram:             Enable 4GB of ZRAM based swap
    dpkg, downloadpackages:    Download the packages necessary to install ELK and the beats for both Debian and RHEL
    ipkg, installpackages:     Install the downloaded packages for the appropriate operating system
    es, setupelastic:          Configure Elasticsearch and ensure it is available with the appropriate password
    ki, setupkibana:           Configure Kibana to access Elasticsearch and allow it to be publicly available
    lo, setuplogstash:         Create an Elasticsearch API key and generate a logstash pipeline that uses both ECS and non-ECS dashboards and routes
    ab, setupauditbeat:        Configure Elasticsearch and Kibana to prepare them for auditbeat data, then configure this device as an endpoint sending auditbeat data
    fb, setupfilebeat:         Configure Elasticsearch and Kibana to prepare them for filebeat data, then configure this device as an endpoint sending filebeat data
    pb, setuppacketbeat:       Configure Elasticsearch and Kibana to prepare them for packetbeat data, then configure this device as an endpoint sending packetbeat data
    beats, installbeats:       Configure this device as an endpoint sending data to the specified ELK stack. Downloads packages from the ELK stack

Configuration notes:
    When installing and configuring ELK, the following ports will be opened up:
      - 514/udp: Syslog input. Generic from Windows and Linux systems
      - 2055/udp: Netflow input. Useful from network firewalls
      - 5044/tcp: Beats input from endpoints
      - 5601/tcp: Kibana web UI
      - 8080/tcp: Python web server hosting packages for download
      - 9001/udp: Palo Alto Syslog input
      - 9002/udp: Cisco FTD Syslog input
      - 9200/tcp: Elasticsearch. Useful to open for Windows to configure routing and indices

    The installation of beats will depend on a Python web server or similar running that can distribute files in the elasticsearch share, by default /opt/es

    Beats will require allowing outbound traffic to port 5044 on the ELK server from host and network based firewalls
END_HELP

    return;
}

sub install {
    my @cmdline = @_;

    setup_zram(@cmdline);
    download_packages(@cmdline);
    install_packages(@cmdline);
    setup_elasticsearch(@cmdline);
    setup_kibana(@cmdline);
    setup_logstash(@cmdline);
    wait_for_kibana(@cmdline);
    setup_auditbeat(@cmdline);
    setup_filebeat(@cmdline);
    setup_packetbeat(@cmdline);

    exit;
}

sub setup_zram {
    if ( !( `lsmod` =~ qr/zram/ ) ) {
        `modprobe zram`
          or return warning("??? Could not load zram\n");
        `zramctl /dev/zram0 --size=4G`
          or return warning("??? Could not initialize /dev/zram0\n");
        `mkswap /dev/zram0`
          or return warning("??? Could not initialize zram swap space\n");
        `swapon --priority=100 /dev/zram0`
          or return warning("??? Could not enable zram swap space\n");

        header("ZRAM has been set up!");
    }
    else {
        header("Skipping ZRAM setup");
    }

    return;
}

sub download_file {
    my ( $url, $file, $done_msg ) = @_;

    if (`which curl 2>/dev/null`) {
        my $pid = fork();
        return $pid if $pid != 0;

        `curl -o $file $url 2>/dev/null >/dev/null`;
        message($done_msg);
        exit;
    }
    elsif (`which wget 2>/dev/null`) {
        my $pid = fork();
        return $pid if $pid != 0;

        `wget -O $file $url 2>/dev/null >/dev/null`;
        message($done_msg);
        exit;
    }

    error("!!! Could not find program to download files with");
    die;
}

sub download_packages_internal {
    my (%args) = @_;

    my $es_dir  = $args{"elasticsearch_share_directory"};
    my $dl_url  = $args{"download_url"};
    my $bdl_url = $args{"beats_download_url"};
    my $es_ver  = $args{"elastic_version"};

    make_path($es_dir);
    chdir($es_dir);

    my @pids = ();

    header "Downloading elastic packages...\n";

    if ( platform() eq "debian" ) {
        foreach my $pkg (qw(elasticsearch logstash kibana)) {
            message "Downloading $pkg deb...\n";
            push @pids,
              (
                download_file(
                    "$dl_url/$pkg/$pkg-$es_ver-amd64.deb", "$pkg.deb",
                    "Done downloading $pkg!\n"
                )
              );
        }
    }
    else {
        foreach my $pkg (qw(elasticsearch logstash kibana)) {
            message "Downloading $pkg rpm...\n";
            push @pids,
              (
                download_file(
                    "$dl_url/$pkg/$pkg-$es_ver-x86_64.rpm", "$pkg.rpm",
                    "Done downloading $pkg!\n"
                )
              );
        }
    }

    foreach my $beat (qw(auditbeat filebeat packetbeat)) {
        message "Downloading $beat rpm and deb...\n";

        push @pids,
          (
            download_file(
                "$bdl_url/$beat/$beat-$es_ver-amd64.deb", "$beat.deb",
                "Done downloading $beat deb!\n"
            ),
            download_file(
                "$bdl_url/$beat/$beat-$es_ver-x86_64.rpm", "$beat.rpm",
                "Done downloading $beat rpm!\n"
            )
          );
    }

    foreach my $pid (@pids) {
        waitpid( $pid, 0 );
    }

    header "Done downloading elastic packages!\n";

    return;
}

sub download_packages {
    my @cmdline = @_;
    my %args    = $sub_parser->(@cmdline);

    if ( $args{"download_shell"} ) {
        my $ns  = create_container( $args{"sneaky_ip"} );
        my $val = run_closure(
            sub {
                download_packages_internal(%args);
            },
            $ns
        );
        destroy_container($ns);
        return $val;
    }
    else {
        return download_packages_internal(%args);
    }
}

sub install_packages {
    my @cmdline = @_;
    my %args    = $sub_parser->(@cmdline);

    my $es_dir = $args{"elasticsearch_share_directory"};

    header "Installing elastic packages...\n";

    chdir $es_dir;

    if ( platform() eq "debian" ) {
        foreach my $pkg (
            qw(elasticsearch logstash kibana filebeat auditbeat packetbeat))
        {
            message "Installing $pkg...\n";
            `dpkg -i $pkg.deb`;
        }
    }
    else {
        foreach my $pkg (
            qw(elasticsearch logstash kibana filebeat auditbeat packetbeat))
        {
            message "Installing $pkg...\n";
            `rpm -i $pkg.rpm`;
        }
    }

    header "Done installing packages\n";

    return;
}

sub setup_elasticsearch {
    my @cmdline = @_;
    my %args    = $sub_parser->(@cmdline);

    my $es_dir = $args{"elasticsearch_share_directory"};

    header "Configuring Elasticsearch\n";

    my $es_password = get_elastic_password();

    `systemctl enable --now elasticsearch`;

    open my $cmd, '|-',
      '/usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic -i'
      or die $!;

    print $cmd "y\n";
    print $cmd $es_password, "\n";
    print $cmd $es_password, "\n";

    close $cmd;

    make_path("/etc/es_certs");
    `cp /etc/elasticsearch/certs/http_ca.crt /etc/es_certs`;
    `cp /etc/elasticsearch/certs/http_ca.crt $es_dir`;
    `chmod +r /etc/es_certs/http_ca.crt`;
    `chmod +r $es_dir/http_ca.crt`;

    header "Elasticsearch configured!\n";

    return;
}

sub setup_kibana {
    my @cmdline = @_;
    my %args    = $sub_parser->(@cmdline);

    header "Configuring Kibana\n";

    my $token =
`/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana`;
    `sudo -u kibana /usr/share/kibana/bin/kibana-setup -t $token`;

    open my $in,  "<", "/etc/kibana/kibana.yml" or die $!;
    open my $out, ">", "/tmp/kibana.yml"        or die $!;
    while (<$in>) {
        s/.*server.host:.*/server.host: "0.0.0.0"/xms;
        print $out $_;
    }
    close $in;
    close $out;
    rename '/tmp/kibana.yml', '/etc/kibana/kibana.yml' or die $!;

    `systemctl enable --now kibana`;

    header "Kibana configured!\n";

    return;
}

sub logstash_config_file {
    my ( $id, $key ) = @_;

    return <<"EOD";
input {
    beats {
        port => 5044
    }
}

output {
    if [\@metadata][beat] == "winlogbeat" {
        elasticsearch {
            hosts => "https://localhost:9200"
            manage_templates => false
            action => "create"
            ssl_enabled => true
            ssl_certificate_authorities => "/etc/es_certs/http_ca.crt"
            api_key => "$id:$key"

            pipeline => "%{[\@metadata][beat]}-%{[\@metadata][version]}-routing"
            data_stream => true
        }
    }

    if [\@metadata][pipeline] {
        elasticsearch {
            hosts => "https://localhost:9200"
            manage_templates => false
            action => "create"
            ssl_enabled => true
            ssl_certificate_authorities => "/etc/es_certs/http_ca.crt"
            api_key => "$id:$key"

            pipeline => "%{[\@metadata][pipeline]}"
            data_stream => true
        }
    }

    elasticsearch {
        hosts => "https://localhost:9200"
        manage_templates => false
        action => "create"
        ssl_enabled => true
        ssl_certificate_authorities => "/etc/es_certs/http_ca.crt"
        api_key => "$id:$key"

        index => "%{[\@metadata][beat]}-%{[\@metadata][version]}"
    }
}
EOD
}

sub setup_logstash {
    header "Configuring Logstash\n";

    my $es_password = get_elastic_password();

    my $api_key_permissions_body = <<'EOD';
{
    "name": "logstash-api-key",
    "role_descriptors": {
        "logstash_writer": {
            "cluster": ["monitor","manage_index_templates","manage_ilm"],
            "index": [{
                "names": ["filebeat-*","winlogbeat-*","auditbeat-*","packetbeat-*","logs-*"],
                "privileges": ["view_index_metadata","read","create","manage","manage_ilm"]
            }]
        }
    }
}
EOD

    open2(
        my $api_out,
        my $api_in,
        "curl",
        "-k",
        "-u",
        "elastic:$es_password",
        "https://localhost:9200/_security/api_key?pretty",
        "-X",
        "POST",
        "-H",
        "content-type: application/json",
        "-d",
        $api_key_permissions_body
    );

    my ( $id, $key );
    while (<$api_out>) {
        if ( $_ =~ qr/"id"\s*:\s*"([^"]+)"/xms ) {
            $id = $1;
        }
        if ( $_ =~ qr/"api_key"\s*:\s*"([^"]+)"/xms ) {
            $key = $1;
        }
    }

    open my $file, '>', '/etc/logstash/conf.d/pipeline.conf' or die $!;
    print $file logstash_config_file( $id, $key );
    close $file;

    `systemctl enable --now logstash`;

    header "Logstash configured!\n";

    return;
}

sub wait_for_kibana {
    header "Waiting for Kibana...";

    while (
        !(
            `curl http://localhost:5601/api/status 2>/dev/null` =~
            qr/"level":"available"/xms
        )
      )
    {
        message "Waiting for Kibana...";
        sleep 1;
    }

    return;
}

sub setup_auditbeat {
    my @cmdline = @_;
    my %args    = $sub_parser->(@cmdline);

    header "Setting up auditbeat";

    my $es_password = get_elastic_password();

    my $es_dir = $args{"elasticsearch_share_directory"};
    my $elk_ip = $args{"elk_ip"};

    open my $abyml, '>', '/etc/auditbeat/auditbeat.yml' or die $!;
    print $abyml <<"EOD";
$AUDITBEAT_BASE_CONFIG

output.elasticsearch:
  hosts: ["https://localhost:9200"]
  transport: https
  username: elastic
  password: "$es_password"
  ssl:
    enabled: true
    certificate_authorities: "/etc/es_certs/http_ca.crt"
EOD
    close $abyml;

    system("auditbeat setup");

    open my $abymlp, '>', '/etc/auditbeat/auditbeat.yml' or die $!;
    print $abymlp <<"EOD";
$AUDITBEAT_BASE_CONFIG

output.logstash:
  hosts: ["$elk_ip:5044"]
EOD
    close $abymlp;

    `systemctl enable auditbeat`;
    `systemctl restart auditbeat`;

    header "Auditbeat is set up";

    return;
}

sub setup_filebeat {
    my @cmdline = @_;
    my %args    = $sub_parser->(@cmdline);

    header "Setting up Filebeat";

    my $es_password = get_elastic_password();

    my $es_dir = $args{"elasticsearch_share_directory"};
    my $elk_ip = $args{"elk_ip"};

    my $fbymlbase = <<'EOD';
$FILEBEAT_BASE_CONFIG

  - module: netflow
    log:
      enabled: true
      var:
        netflow_host: localhost
        netflow_port: 2055
        internal_networks:
          - private

  - module: panw
    panos:
      enabled: true
      var.syslog_host: 0.0.0.0
      var.syslog_port: 9001
      var.log_level: 5

  - module: cisco
    ftd:
      enabled: true
      var.syslog_host: 0.0.0.0
      var.syslog_port: 9002
      var.log_level: 5

EOD

    open my $fbyml, '>', '/etc/filebeat/filebeat.yml' or die $!;
    print $fbyml <<"EOD";
$FILEBEAT_BASE_CONFIG

output.elasticsearch:
  hosts: ["https://localhost:9200"]
  transport: https
  username: "elastic"
  password: "$es_password"
  ssl:
    enabled: true
    certificate_authorities: "/etc/es_certs/http_ca.crt"
EOD
    close $fbyml;

    system("filebeat setup");

    open my $fbymlp, '>', '/etc/filebeat/filebeat.yml' or die $!;
    print $fbymlp <<"EOD";
$FILEBEAT_BASE_CONFIG

output.logstash:
  hosts: ["$elk_ip:5044"]
EOD
    close $fbymlp;

    `systemctl enable filebeat`;
    `systemctl start filebeat`;

    header "Filebeat is set up";

    return;
}

sub setup_packetbeat {
    my @cmdline = @_;
    my %args    = $sub_parser->(@cmdline);

    header "Setting up Filebeat";

    my $es_password = get_elastic_password();

    my $es_dir = $args{"elasticsearch_share_directory"};
    my $elk_ip = $args{"elk_ip"};

    open my $pbyml, '>', '/etc/packetbeat/packetbeat.yml' or die $!;
    print $pbyml <<"EOD";
$PACKETBEAT_BASE_CONFIG

output.elasticsearch:
  hosts: ["https://localhost:9200"]
  transport: https
  username: "elastic"
  password: "$es_password"
  ssl:
    enabled: true
    certificate_authorities: "/etc/es_certs/http_ca.crt"
EOD
    close $pbyml;

    system("packetbeat setup");

    open my $pbymlp, '>', '/etc/packetbeat/packetbeat.yml' or die $!;
    print $pbymlp <<"EOD";
$PACKETBEAT_BASE_CONFIG

output.logstash:
  hosts: ["$elk_ip:5044"]
EOD
    close $pbymlp;

    `systemctl enable packetbeat`;
    `systemctl start packetbeat`;

    header "Packetbeat is set up";

    return;
}

sub install_beats {
    my @cmdline = @_;
    my %args    = $sub_parser->(@cmdline);

    my $elk_ip         = $args{"elk_ip"};
    my $elk_share_port = $args{"elk_share_port"};
    my $download_shell = $args{"download_shell"};
    my $sneaky_ip      = $args{"sneaky_ip"};

    return;
}

1;
