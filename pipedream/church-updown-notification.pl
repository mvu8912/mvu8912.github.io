#!/usr/bin/env perl

# This chunk of stuff was generated by App::FatPacker. To find the original
# file's code, look for the end of this BEGIN block or the string 'FATPACK'
BEGIN {
my %fatpacked;

$fatpacked{"MF/DockerCompose.pm"} = '#line '.(1+__LINE__).' "'.__FILE__."\"\n".<<'MF_DOCKERCOMPOSE';
  package MF::DockerCompose;
  
  use strict;
  use warnings;
  use base 'Exporter';
  
  our @EXPORT_OK = qw(
    exec_args
  );
  
  sub exec_args {
      (
          ( $ENV{_USER}  ? ( -u        => $ENV{_USER} )  : () ),
          ( $ENV{_CWD}   ? ( -w        => $ENV{_CWD} )   : () ),
          ( $ENV{_INDEX} ? ( '--index' => $ENV{_INDEX} ) : () ),
          ( $ENV{_STDIN} ? ('-T') : () ),
          _env_args(),
      )
  }
  
  sub _env_args {
      my @exec_args;
  
      while ( my ( $key, $val ) = each %ENV ) {
          if ( $key =~ m/^_ENV_(.+)/ ) {
              push @exec_args, -e => "$1=$val";
          }
      }
  
      return @exec_args;
  }
  
  1;
MF_DOCKERCOMPOSE

$fatpacked{"MF/Plugin.pm"} = '#line '.(1+__LINE__).' "'.__FILE__."\"\n".<<'MF_PLUGIN';
  package MF::Plugin;
  
  use Moo;
  
  use MF::Utils qw(
    cd
    defor
    load_yaml
    makedir
    makedirs
    openfile
    touchfile
    writefile
  );
  
  has name         => ( is => 'ro', required => 1, );
  has base_dir     => ( is => 'ro', required => 1, );
  has my_files_dir => ( is => 'ro', required => 1, );
  has plugins_dir  => ( is => 'ro', required => 1, );
  
  has plugin_dir => (
      is      => 'ro',
      lazy    => 1,
      default => sub {
          my ($self) = @_;
          $self->my_files_dir . '/' . $self->name;
      },
  );
  
  has is_installed => (
      is      => 'ro',
      lazy    => 1,
      default => sub {
          my ($self) = @_;
          -f $self->plugin_dir . '/installed'
      },
  );
  
  has is_enabled => (
      is      => 'ro',
      lazy    => 1,
      default => sub {
          my ($self) = @_;
          return 0 if !$self->is_installed;
          return 1 if !-f $self->plugin_dir . '/disabled';
      },
  );
  
  has version => (
      is      => 'ro',
      lazy    => 1,
      default => sub {
          my ($self) = @_;
          my $version = openfile $self->plugin_dir . '/version';
          return defor $version, 1;
      },
  );
  
  sub activate {
      my ($self) = @_;
      unlink $self->plugin_dir . '/disabled';
  }
  
  sub deactivate {
      my ($self) = @_;
      touchfile $self->plugin_dir . '/disabled';
  }
  
  my $get_file_ext = sub {    # Private Function
      my ($file) = @_;
  
      if ( $file =~ m/(.+)\.(tb[z]?2|tar\.b[z]?2|tgz|tar\.gz|txz|tar.xz)$/i ) {
          return ( $1, $2 );
      }
      else {
          return;
      }
  };
  
  sub install_from_url {
      my ( $self, %options ) = @_;
  
      my $url = defor $options{url}, $self->name
        or return;
  
      my ( $filename ) = ( $url =~ m/.*\/(.*)/ );
  
      $filename =~ s/\?.*//;
      $filename =~ s/\#.*//;
  
      return if !$get_file_ext->($filename);
  
      cd $self->plugins_dir => sub {
          my ($dir) = @_;
  
          system sprintf "curl -Lk %s > %s",
            map { quotemeta } ( $url, $filename );
  
          $self->install_from_archive(%options, archive => "$dir/$filename");
      };
  }
  
  sub install_from_archive {
      my ( $self, %options ) = @_;
  
      my $archive = defor $options{archive}, $self->name;
  
      if ( !-f $archive ) {
          $archive = $self->plugins_dir . "/$archive";
          if ( !-f $archive ) {
              die "Plugin Installation File is not found. ([x] $archive)";
          }
      }
  
      my ( $path, $plugin ) = ( $archive =~ m/(.*)\/(.*)/ );
  
      my ( $file_with_version, $ext ) = $get_file_ext->($archive)
        or return;
  
      my ( $plugin_dir, $ver ) = split /-/, $file_with_version;
      my ( $name ) = ( $plugin_dir =~ m/.*\/(.*)/ );
  
      if (!$ver) {
          warn "Plugin Archive File missing version. ([x] $plugin)";
          return;
      }
  
      $ver =~ s/[^\d\.]//g;
      $ver = defor $ver => '1.0';
  
      my $old_plugin = Service->MF->Plugins->plugin(name => $name);
  
      return system qw(rm), $archive
        if $old_plugin->is_installed
        && $old_plugin->version >= $ver
        && !$options{reinstall};
  
      my $switch = '-x';
      $switch .= 'z' if $ext =~ /gz/;
      $switch .= 'j' if $ext =~ /b[z]?2/;
      $switch .= 'x' if $ext =~ /xz/;
      $switch .= 'f';
  
      system qw(tar), $switch, $archive, -C => makedir $plugin_dir;
  
      if ( my $list = load_yaml file => "$plugin_dir/plugins.yml" ) {
          foreach my $url(@$list) {
              $self->install_from_url(url => $url, %options);
          }
      }
  
      writefile $self->my_files_dir . "/$name/version", content => $ver;
  
      system qw(mv -v), $archive, makedir $self->my_files_dir . "/$name";
  
      $self->install_from_plugins_dir(
          path   => $self->plugins_dir,
          plugin => $name,
      );
  }
  
  my $transfer_new_plugin_dir = sub {    # private method
      my ( $self, $where, $name, %options ) = @_;
  
      makedir $where if $options{mkdir};
  
      return '' if !-d $where;
  
      my $store = makedir $self->my_files_dir . "/$name/$where";
  
      system qw(rsync --delete -Pa --exclude stateful), "$where/", $store;
  
      system qw(rsync --ignore-existing -Pa), makedirs "$where/stateful/",
        $self->my_files_dir . "/$name/$where/stateful";
  
      my $target = makedir( $self->base_dir . "/$where/" ) . $name;
  
      symlink $store, $target;
  };
  
  my $clean_my_file_dir = sub {
      my ( $self, $name ) = @_;
      makedir 'empty_dir';
      system qw(rsync --delete -Pa --exclude stateful), "empty_dir/",
        $self->my_files_dir . "/$name";
  };
  
  my $transfer_new_plugin_file = sub {    # private method
      my ( $self, $file, $name ) = @_;
      return if !-f $file;
      system qw(cp -v), $file, makedir $self->my_files_dir . "/$name";
  };
  
  sub install_from_plugins_dir {
      my ( $self, %options ) = @_;
  
      my $path = $options{path} || $self->plugins_dir;
      my $name = $options{plugin}
        or die "Mising Plugin Name to install from plugins directory";
  
      my $plugin_dir = "$path/$name";
  
      die "Plugin Directory is not found. ([x] $plugin_dir)"
        if !-d $plugin_dir;
  
      print "Install Plugin: $name\n";
  
      my ( $copyd, $copyf ) =
        ( $transfer_new_plugin_dir, $transfer_new_plugin_file );
  
      cd $plugin_dir => sub {
          $self->$clean_my_file_dir($name);
  
          makedir $self->my_files_dir . "/$name/stateful";
  
          $self->$copyf( 'docker-compose.yml', $name );
          $self->$copyf( 'deb.packages',       $name );
          $self->$copyd( 'deb.files', $name );
  
          if ( -f $ENV{MF_DEB_LIST_FILE} ) {
              system qw(apt-get install -y), split /\n/,
                openfile $ENV{MF_DEB_LIST_FILE};
          }
  
          if ( -f 'cpanfile' ) {
              die "Env: PERL_CARTON_PATH is not defined."
                if !$ENV{PERL_CARTON_PATH};
              system qq{HOME=/tmp carton install};
              $self->$copyf( 'cpanfile',          $name );
              $self->$copyf( 'cpanfile.snapshot', $name );
          }
  
          $self->$copyd( views  => $name );
          $self->$copyd( public => $name );
          $self->$copyd( config => $name );
          $self->$copyd( bin    => $name );
          $self->$copyd( lib    => $name );
          $self->$copyd( data   => $name, mkdir => 1 );
  
          touchfile $self->my_files_dir . "/$name/installed";
  
      };
  
      system qw(rm -fr), $plugin_dir;
  
      return 1;
  }
  
  1;
MF_PLUGIN

$fatpacked{"MF/Services.pm"} = '#line '.(1+__LINE__).' "'.__FILE__."\"\n".<<'MF_SERVICES';
  package MF::Services;
  
  use strict;
  use warnings;
  
  use Bread::Board ();
  use MF::Utils qw(
    add_lib
    create_method
    defor
    listdirs
    mf_envs
  );
  
  my %env = mf_envs;
  
  add_lib $env{MF_LIB_DIR};
  
  my @lib_paths = ( $env{MF_CORE_SERVICE_DIR}, $env{MF_LIB_DIR} );
  
  my $get_service_classname = sub {
      my ($full_path) = @_;
  
      foreach my $dir (@lib_paths) {
          if ( $full_path =~ m/\Q$dir\E/ ) {
              $full_path =~ s/$dir\///;
              $full_path =~ s/\.pm$//;
              return join '::', split /\//, $full_path;
          }
      }
  
      if ( $ENV{DEV} ) {
          warn "Could not find package name from $full_path";
      }
  };
  
  my $process_service_file;
  
  $process_service_file = sub {
      my %options = @_;
  
      my $path = $options{path}
        or die "Missing path of the service file";
  
      add_lib "$path/";
  
      my $parent_container = $options{parent_container}
        or die "Missing parent_container";
  
      my $family_tree = $options{family_tree};
  
      my $service_file = "$path/$env{MF_SERVICE_FILE}";
  
      if ( !-f $service_file ) {
          return;
      }
  
      require $service_file;
  
      my $service_file_package_name = $get_service_classname->($service_file);
  
      my $services = $service_file_package_name->services
        or die "$service_file_package_name file is missing"
        . ' return list of services';
  
      die "The return payload from $service_file_package_name needs "
        . "to be HashRef. (? $services)"
        if !UNIVERSAL::isa( $services, 'HASH' );
  
      my $plugin;
  
      if ( $service_file_package_name->can('container_name') ) {
          $plugin = defor $service_file_package_name->container_name, '';
          $plugin =~ s/(\w+)/$1/g;
      }
  
      if ( !$plugin ) {
          ( undef, $plugin ) = ( $path =~ m/(.*)\/(.*)/ );
      }
  
      my $plugin_container = Bread::Board::Container->new( name => $plugin );
  
      my $family_class = ( $family_tree ? "${family_tree}::" : '' ) . $plugin;
  
      my ($service_class) = ( "Service::$family_class" =~ m/(.*)::/ );
  
      create_method $service_class, $plugin, sub {
          bless {
              services  => $services,
              container => {
                  parent => $parent_container,
                  this   => $plugin_container,
              },
            },
            "Service::$family_class";
      };
  
      $parent_container->add_sub_container($plugin_container);
  
      while ( my ( $service_name, $meta ) = each %$services ) {
          if ( $service_name eq '_include' || $service_name eq '_includes' ) {
              $meta = [$meta] if !UNIVERSAL::isa( $meta, 'ARRAY' );
  
            FIND_DIR: foreach my $dir (@lib_paths) {
                  foreach my $child (@$meta) {
                      my $path = "$dir/$child";
                      $path =~ s/::/\//g;
  
                      $path =~ s/\/Service$//;
  
                      next if !-d $path;
  
                      $process_service_file->(
                          path             => $path,
                          plugin           => $family_class . "::$child",
                          parent_container => $plugin_container,
                          family_tree      => $family_class,
                      );
                  }
              }
          }
          else {
              my $injection =
                exists $meta->{block}
                ? 'Bread::Board::BlockInjection'
                : 'Bread::Board::ConstructorInjection';
  
              if ($meta->{class}) {
                  my $class = $meta->{class};
                  $class =~ s/::/\//;
                  require "$class.pm";
              }
  
              $plugin_container->add_service(
                  $injection->new( name => $service_name, %$meta ) );
  
              create_method "Service::$family_class", $service_name, sub {
                  my ( undef, %args ) = @_;
                  $plugin_container->resolve(
                      service    => $service_name,
                      parameters => \%args,
                  );
              };
          }
      }
  };
  
  my $MF = Bread::Board::Container->new( name => 'Manifestation' );
  
  listdirs \@lib_paths => sub {
      my %row = @_;
      $process_service_file->(
          path             => $row{path},
          plugin           => $row{plugin},
          parent_container => $MF,
          family_tree      => '',
      );
    },
    {
      dir_only   => 1,
      die_no_dir => 0,
      alias      => 'plugin',
    };
  
  no MF::Utils;
  
  1;
MF_SERVICES

$fatpacked{"MF/Utils.pm"} = '#line '.(1+__LINE__).' "'.__FILE__."\"\n".<<'MF_UTILS';
  package MF::Utils;
  
  use strict;
  use warnings;
  use Cwd qw(cwd);
  use base 'Exporter';
  
  our @EXPORT_OK = qw(
    add_lib
    argv
    cd
    create_method
    defor
    deforset
    env
    file
    folder
    hash2str
    listdir
    listdirs
    load_json
    load_yaml
    makedir
    makedirs
    mf_envs
    openfile
    opts
    run_command
    set_env_from_file
    template_file
    touchfile
    writefile
    writefile_json
  );
  
  my %MF_ENV = ();
  
  sub add_lib {
      my ($dir) = @_;
  
      return $dir if !-d $dir;
      return $dir if grep { $_ eq $dir } @INC;
  
      push @INC, $dir;
  
      return $dir;
  }
  
  sub defor {
      my ( $default, $or ) = @_;
      return ( defined($default) && length($default) ) ? $default : $or;
  }
  
  sub deforset {
      return $_[0] = defor(@_);
  }
  
  sub env {
      my ($key) = @_;
      return defor $ENV{$key}, defor $MF_ENV{$key}, '';
  }
  
  sub mf_envs {
      if ( !%MF_ENV ) {
          foreach my $key ( keys %ENV ) {
              next if $key !~ /^MF_/;
              $MF_ENV{$key} = $ENV{$key};
          }
      }
  
      if ( !%MF_ENV ) {
          set_env_from_file("/web/mf.env");
      }
  
      return wantarray ? %MF_ENV : \%MF_ENV;
  }
  
  sub hash2str {
      my $hash    = shift @_;
      my %options = @_ if @_;
  
      my $quotemeta = $options{quotemeta};
      my $join      = defor( $options{join}, ' ' );
  
      my @pairs = '';
  
      foreach my $key ( sort keys %$hash ) {
          push @pairs, sprintf "%s=%s",
            map { $quotemeta ? quotemeta : $_ } ( $key, $hash->{$key} );
      }
  
      return join $join, @pairs;
  }
  
  sub listdirs {
      my $dirs    = shift;
      my $code    = shift;
      my $options = shift || {};
  
      die "$dirs is not ArrayRef" if !$dirs || !UNIVERSAL::isa( $dirs, 'ARRAY' );
  
      my %list =
        map { $_ => [ listdir( $_, $code, $options ) ] } grep { $_ } @$dirs;
  
      return wantarray ? %list : \%list;
  }
  
  sub listdir {
      my $dir     = shift or return;
      my $code    = shift;
      my $options = shift || {};
  
      $code = defor( $code, sub { } );
  
      my @list = ();
  
      if ( !-d $dir ) {
          if ( $options->{die_no_dir} ) {
              die "Dir: $dir is not exists";
          }
          return @list;
      }
  
      opendir( my $DIR, $dir );
  
      while ( my $item = readdir($DIR) ) {
          next if $item eq '.' || $item eq '..';
  
          my $path = "$dir/$item";
  
          next if $options->{dir_only}  && !-d $path;
          next if $options->{file_only} && !-f $path;
  
          my %item = ();
  
          if ( my $alias = $options->{alias} ) {
              $item{$alias} = $item;
          }
          else {
              $item{item} = $item;
          }
  
          my %info = (
              %item,
              dir  => $dir,
              path => $path,
              type => -f $path ? 'file' : 'dir',
              size => -s $path,
          );
          my $action = $code->(%info);
  
          next if !$action || $action eq 'next';
  
          push @list, \%info;
  
          last if $action eq 'last';
          redo if $action eq 'redo';
      }
  
      closedir($DIR);
  
      return @list;
  }
  
  sub makedirs {
      map { makedir($_) } @_;
  }
  
  sub makedir {
      my $dir    = shift;
      my $switch = 'p';
      $switch .= 'v' if env('DEV');
      unlink $dir if -f $dir;
      system qw(mkdir), "-$switch", $dir if !-d $dir;
      return $dir;
  }
  
  sub set_env_from_file {
      my ($file) = @_;
  
      my $fh = openfile(
          $file,
          return_fh   => 1,
          die_message => "env file is not found",
      );
  
      while ( my $line = <$fh> ) {
          next if !$line || $line =~ /^[\s\t]*#/;
          chomp $line;
          $line =~ s/\$[\{]?([^\}]+)[\}]?/env($1)/xg;
          $line =~ s/\$\w+/env($1)/xg;
          my ( $key, $val ) = split /=/, $line, 2;
          $ENV{$key} = $MF_ENV{$key} = $val;
      }
  }
  
  sub touchfile {
      my ($path) = @_;
      writefile( $path, append => 1, content => '' );
  }
  
  sub writefile {
      my ( $path, %options ) = @_;
  
      my $encode = defor( $options{encode}, '' );
      my $mode   = $options{append} ? '>>' : '>';
  
      if ( open my $fh, $mode . $encode, $path ) {
          return $fh if $options{return_fh};
          print $fh $options{content};
          return
              $options{return_path}    ? $path
            : $options{return_content} ? $options{content}
            :                            undef;
      }
      elsif ( my $die = $options{die_message} ) {
          die sprintf $die, $!;
      }
      elsif ( my $warn = $options{warn_message} ) {
          warn sprintf $warn, $!;
      }
  }
  
  sub writefile_json {
      my ( $path, %options ) = @_;
  
      my $data = $options{data}
        or return;
  
      require JSON;
  
      my $json = JSON->new->canonical;
  
      $json->pretty if $options{pretty} || $ENV{DEV};
      $json->utf8   if $options{utf8};
  
      writefile(
          $path, %options,
          encode  => $options{utf8} ? 'utf8' : '',
          content => $json->encode($data)
      );
  }
  
  sub openfile {
      my ( $path, %options ) = @_;
  
      my $fh;
  
      if (UNIVERSAL::isa($path, 'GLOB')) {
          $fh = $path;
      }
      else {
          my $encode = defor( $options{encode}, '' );
          open $fh, "<$encode", $path;
      }
  
      if ( $fh ) {
          return $fh if $options{return_fh};
          local $/;
          return <$fh>;
      }
      elsif ( my $die = $options{die_message} ) {
          die sprintf $die, $!;
      }
      elsif ( my $warn = $options{warn_message} ) {
          warn sprintf $warn, $!;
      }
      elsif ( $options{return_path_on_error} ) {
          return $path;
      }
  
      return;
  }
  
  sub load_yaml {
      my (%options) = @_;
  
      my $yaml;
  
      if ( my $file = delete $options{file} ) {
          $yaml = openfile( $file, %options )
            or return;
      }
      elsif ( $yaml = $options{yaml} ) { }
      else                             { return }
  
      require YAML;
      my $data = YAML::Load($yaml);
  
      return $options{want} ? $data->{$options{want}} : $data;
  }
  
  sub load_json {
      my (%options) = @_;
  
      my $json;
  
      if ( my $file = delete $options{file} ) {
          $json = openfile( $file, %options )
            or return;
      }
      elsif ( $json = $options{json} ) { }
      else                             { return }
  
      require JSON::PP;
      my $data = JSON::PP->new->utf8->decode($json);
  
      return $options{want} ? $data->{$options{want}} : $data;
  }
  
  sub create_method {
      my ( $class, $method, $code ) = @_;
  
      return if $class->can($method);
  
      no strict 'refs';
  
      *{ $class . '::' . $method } = $code;
  
      print "New method: ${class}::$method\n" if $ENV{DEV2};
  
      use strict;
  }
  
  sub cd {
      my ( $path, $code, %options ) = @_;
  
      return if !-d $path;
  
      my $original = cwd();
  
      chdir $path;
  
      eval { $code->($path) };
  
      my $error = $@;
  
      chdir $original;
  
      die $@ if $@;
  }
  
  sub opts {
      my %options;
  
      if ($#_ == 0 && UNIVERSAL::isa($_[0], 'HASH')) {
          %options = %{$_[0]};
      }
      else {
          %options = @_;
      }
  
      return wantarray ? %options : \%options;
  }
  
  my $find_stateful_item = sub {
      my ( $where, $plugin, @options ) = @_;
  
      my $options = opts(@options);
  
      my $file   = $options->{file};
      my $folder = $options->{folder};
  
      die "Can only load either folder or file"
        if $file && $folder;
  
      die "Missing file or folder to load"
        if !$file && !$folder;
  
      my $base = $ENV{"MF_${where}_DIR"};
  
      my $dir          = "$base/$plugin";
      my $stateful_dir = "$dir/stateful";
  
      my $item = defor( $file, $folder );
      my $type = $file ? 'file' : 'folder';
      my %got;
  
      if (
          ( $options->{new} && -d $stateful_dir )
          || (
              $type eq 'file'
              ? -f "$stateful_dir/$item"
              : -d "$stateful_dir/$item"
          )
        )
      {
          %got = (
              dirs   => [ $stateful_dir, $dir ],
              dir    => $stateful_dir,
              path   => "$stateful_dir/$item",
              plugin => "$plugin/stateful/$item",
              $type  => $item,
              status => 'stateful',
          );
      }
      elsif (( $options->{new} && -d $dir )
          || ( $type eq 'file' ? -f "$dir/$item" : -d "$dir/$item" ) )
      {
          %got = (
              dirs   => [ $stateful_dir, $dir ],
              dir    => $dir,
              path   => "$dir/$item",
              plugin => "$plugin/$item",
              $type  => $item,
              status => 'default',
          );
      }
      elsif ( $options->{stop_when_not_found} ) {
          die "$where $type is not found. ([x] $plugin/$item)";
      }
  
      return if !%got;
  
      return $options->{want} ? $got{$options->{want}} : \%got;
  };
  
  sub file {
      my ( $where, $plugin, $file, @options ) = @_;
  
      my %options = opts(@options);
  
      $options{file} = $file;
  
      $find_stateful_item->( $where, $plugin, %options );
  }
  
  sub folder {
      my ( $where, $plugin, $folder, @options ) = @_;
  
      my %options = opts(@options);
  
      $options{folder} = $folder;
  
      $find_stateful_item->( $where, $plugin, %options );
  }
  
  sub template_file {
      my ( $plugin, $file, @options ) = @_;
  
      $file .= '.tt'
        if $file !~ m/\.(tt)$/;
  
      return file( VIEWS => $plugin, $file, opts(@options), want => 'plugin' );
  }
  
  sub argv {
      return if !@ARGV;
  
      my %options = @_;
  
      my %mapping;
      my %default_value;
      my %is_list;
  
      while ( my ( $key, $switch ) = each %options ) {
          if (UNIVERSAL::isa($switch, 'HASH')) {
              $default_value{$key} = defor $switch->{default}, '';
              $is_list{$key} = $switch->{is_list};
              $switch = $switch->{switch} or die "Missing switch for $key";
          }
          if ( ref $switch ) {
              map { $mapping{$_} = $key } @$switch;
          }
          else {
              $mapping{$switch} = $key;
          }
          $mapping{"--$key"} = $key;
      }
  
      die "Missing key mapping" if !%mapping;
  
      my %got = ();
  
      for ( my $i = 0 ; $i <= $#ARGV ; $i++ ) {
          my $item = $ARGV[$i];
  
          if ( $item eq '--' ) {
              $got{o_} = [ @ARGV[ $i+1 .. $#ARGV ] ];
              last;
          }
          elsif ( $item =~ m/^(?:--(no[-]?|)([^-]{2,})|-([^-]))$/ ) {
              my ( $no, $long, $short ) = ( $1, $2, $3 );
  
              my $key;
  
              if    ( defined $long  && ( $key = $mapping{"--$long"} ) ) { }
              elsif ( defined $short && ( $key = $mapping{"-$short"} ) ) { }
              else {
                  $key = 'o_' . defor( $long, $short );
              }
  
              next if !defined $key;
  
              my $val = defor( $ARGV[ $i + 1 ], '--the-end' );
  
              if ( $val =~ m/^[-]{1,2}/ ) {
                  $val = $no ? 0 : 1;
              }
  
              deforset($val, $default_value{$key});
  
              if ($is_list{$key}) {
                  push @{deforset($got{$key}, [])}, $val;
              }
              else {
                  $got{$key} = $val;
              }
          }
      }
  
      $got{o_ARGV} = \@ARGV if %got;
  
      return wantarray ? %got : \%got;
  }
  
  sub run_command {
      my %options = @_;
  
      my $cmd     = defor( $options{exec}, $options{system} ) or return;
      my $args    = $options{args};
      my $chdir   = $options{chdir};
      my %env     = %{ defor( $options{env}, {} ) };
      my $capture = $options{capture};
  
      my %mf_env = mf_envs();
  
      my $env = hash2str(
          { %mf_env, %env },
          quotemeta => 1,
          join      => ' ',
      );
  
      my $run = "$env " if $env;
  
      $run .= $cmd;
  
      $args = defor( join( ' ', map { quotemeta } @$args ), '' );
  
      $run =~ s/\{\{args\}\}/$args/;
  
      print ">> $run\n" if defor( $ENV{DEV}, $env{DEV} );
  
      if ( $options{exec} ) {
          chdir $chdir if $chdir;
          exec $run;
      }
  
      my %captured;
  
      my $execute = sub {
          return system $run if !$capture;
  
          require Capture::Tiny;
  
          my ( $stdout, $stderr, @result ) =
            Capture::Tiny::capture( sub { system $run } );
  
          %captured = (
              stdout => $stdout,
              stderr => $stderr,
              result => \@result,
          );
      };
  
      $chdir ? cd( $chdir => $execute ) : $execute->();
  
      return if !$capture;
  
      return wantarray ? %captured : \%captured;
  }
  
  1;
MF_UTILS

s/^  //mg for values %fatpacked;

my $class = 'FatPacked::'.(0+\%fatpacked);
no strict 'refs';
*{"${class}::files"} = sub { keys %{$_[0]} };

if ($] < 5.008) {
  *{"${class}::INC"} = sub {
    if (my $fat = $_[0]{$_[1]}) {
      my $pos = 0;
      my $last = length $fat;
      return (sub {
        return 0 if $pos == $last;
        my $next = (1 + index $fat, "\n", $pos) || $last;
        $_ .= substr $fat, $pos, $next - $pos;
        $pos = $next;
        return 1;
      });
    }
  };
}

else {
  *{"${class}::INC"} = sub {
    if (my $fat = $_[0]{$_[1]}) {
      open my $fh, '<', \$fat
        or die "FatPacker error loading $_[1] (could be a perl installation issue?)";
      return $fh;
    }
    return;
  };
}

unshift @INC, bless \%fatpacked, $class;
  } # END OF FATPACK CODE

use strict;
use warnings;

use lib 'lib';
use JSON::PP;
use MF::Utils;

my $default_email = q{church@freeitsupport.org.uk};

my %profiles = (
    791318406 => {
        url   => "https://stjohnshartford.freeitsupport.org.uk",  ## Testing
    },
    791227600 => {
        email => q{office@stjohnshartford.org},
        url   => "https://stjohnshartford.freeitsupport.org.uk",
    },
    791060001 => {
        email => q{info@stjohnvianney.co.uk},
        url   => "https://stjohnvianney.freeitsupport.org.uk",
    },
    790843428 => {
        email => q{church.office@smem.org.uk},
        url   => "https://smem.freeitsupport.org.uk",
    },
    791085019 => {
        email => q{office@waltonbc.org},
        url   => "https://waltonbc.freeitsupport.org.uk",
    },
);

my $email_template = q{
Greeting,
<br>
<br>The {{steps.trigger.event.query.monitorFriendlyName}} website ({{steps.trigger.event.query.monitorURL}}) is {{steps.trigger.event.query.alertTypeFriendlyName}}
<br>
<br>It is currently {{status}}
<br>
<br>Event happened at {{steps.trigger.context.ts}}
<br>
<br>We will update you if anything changes again. 
<br>
{{duration.text}}{{dashboard.text}}
<br>-- 
<br>
<br>Sincerely,
<br>
<br>Website Notication @ <b>Free IT Support</b>
<br><b>T</b>: 07414645481
<br><b>E</b>: Church@FreeITSupport.org.uk
<br><b>W</b>: https://FreeITSupport.org.uk
};

use MF::Utils qw(load_json defor);

my %data;

$data{steps} = load_json file => $ENV{PIPEDREAM_STEPS};
$data{status} = _status( $data{steps}{trigger}{event}{query}{alertDetails} );
$data{duration}{text} =
  _duration( $data{steps}{trigger}{event}{query}{alertFriendlyDuration} );
my $monid = $data{steps}{trigger}{event}{query}{monitorID};
$data{dashboard}{text} = _dashboard( $monid );

_tt( $email_template, \%data );

my $subject = sprintf "Website %s is %s",
    $data{steps}{trigger}{event}{query}{monitorURL},
    $data{steps}{trigger}{event}{query}{alertTypeFriendlyName};

_email( $monid, $subject, $email_template );

sub _tt {
    my ( $tt, $data ) = @_;
    $_[0] =~ s|\{\{([^}]+)\}\}|
        my $token = $1;
        $token =~s/\./\}\{/g;
        $token = sprintf "\$data->{%s}", $token;
        my $v = defor eval($token), "";
        print "Token: $token=$v\n"; $v
    |eg;
}

sub _status {
    my ($status) = @_;

    return if !$status;

    my ( $code, $readable ) = split / - /, $status;

    return $readable;
}

sub _dashboard {
    my ($mon_id) = @_;

    my $url = $profiles{$mon_id}{url}
      or return;

    return qq{<br><br>Status Update <a href="$url">$url</a>};
}

sub _duration {
    my ($duration) = @_;

    return if !$duration;

    return "<br>It was down for $duration";

}

sub _num {
    my $num = shift;
    return ( $num, $num > 1 ? "s" : "" );
}

sub _email {
    my ($id, $subject, $email) = @_;

    my $from = $default_email;
    my $cc = $default_email;
    my $to = defor $profiles{$id}{email}, $cc;
    my %data = (
       "subject" => $subject,
       "content" => [
          {
             "type" => "text/html",
             "value" => $email,
          }
       ],
       "from" => {
          "email" => $from
       },
       "personalizations" => [
          {
             "to" => [
                {
                   "email" => $to,
                }
             ]
          }
       ],
    );

    if ($to ne $cc) {
        $data{personalizations}[0]{cc} = [{email => $cc}];
    }

    system qw(
        curl --request POST
             --url https://api.sendgrid.com/v3/mail/send
             --header), "Authorization: Bearer $ENV{SendGrid}", qw(
             --header), "Content-Type: application/json", qw(
             --data), JSON::PP->new->encode(\%data);
}