package LUCCDC::Jiujitsu::Commands::elk;
use strictures 2;

use Carp;
use File::Path qw(make_path);
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
        val  => 8000,
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
    'setupzram'        => \&setup_zram,
    'downloadpackages' => \&download_packages,
    'installpackages'  => \&install_packages,
    'setupelastic'     => \&setup_elasticsearch,
    'setupkibana'      => \&setup_kibana,
    'setuplogstash'    => \&setup_logstash,
);

my %helpcommands = (
    '--help' => \&help,
    '-h'     => \&help
);

my $toplevel_parser = parser( \@options, \%subcommands );
my $sub_parser      = parser( \@options, \%helpcommands );

sub run {
    my @cmdline = @_;

    die "You must be root to install ELK" unless $> == 0;
    die "A hostname must be set!"
      if `hostnamectl` =~ qr/Static\+hostname:\s+\(unset\)/xms;

    $toplevel_parser->(@cmdline);

    exit;
}

sub help {

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

    header "Done downloading elastic packages!";

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

sub setup_logstash {
    header "Configuring Logstash\n";

    return;
}

sub wait_for_kibana {

}

sub setup_auditbeat {

}

sub setup_filebeat {

}

sub setup_packetbeat {

}

sub install_beats {

}

1;
