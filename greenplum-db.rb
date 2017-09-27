class GreenplumDb < Formula
  desc "Greenplum Database"
  homepage "http://greenplum.org"
  url "https://github.com/greenplum-db/gpdb/archive/5.0.0.tar.gz"
  sha256 "4bb8c353831889d53a743e7ffcaac3aa1b60aef7facf7cd9e3bee2887470aafe"
  head "https://github.com/greenplum-db/gpdb.git"

  depends_on "libyaml" => :build # --enable-mapreduce
  depends_on "libevent" => :build # gpfdist
  depends_on "apr" => :build # gpperfmon
  depends_on "apr-util" => :build # gppermon

  depends_on "gporca" => :build # --enable-orca

  depends_on "python" => :run

  depends_on "go" => :optional
  depends_on "gdb" => :optional

  def install
    # additional pip dependencies to run
    system "pip", "install -i https://pypi.tuna.tsinghua.edu.cn/simple", "lockfile",
                             "psi",
                             "paramiko",
                             "pysql",
                             "psutil",
                             "setuptools",
                             "unittest2",
                             "parse",
                             "pexpect",
                             "mock",
                             "pyyaml",
                             "git+https://github.com/behave/behave@v1.2.4",
                             "pylint"

    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"

    system "make", "install"

    mkdir "#{prefix}/demo"
    cp "gpAux/gpdemo/demo_cluster.sh", "#{prefix}/demo"
    cp "gpAux/gpdemo/probe_config.sh", "#{prefix}/demo"
    cp "gpAux/gpdemo/lalshell", "#{prefix}/demo"
    cp "gpAux/gpdemo/Makefile", "#{prefix}/demo"
  end

  def caveats; <<-EOS.undent
    This Greenplum Database distribution is intended for basic evaluation
    and testing on Mac OS systems. It is not officially supported by Pivotal,
    and it is not intended for production use. To report issues, please visit
    https://github.com/greenplum-db/gpdb/issues.

    Congratulations! A copy of GPDB is installed under #{prefix}.

    1. enable `Remote Login` under `System Preferences -> Sharing`
    2. setup the ssh, with following example

    ssh-keygen
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys

    3. run the following scripts to setup environment
    ```
    #!/bin/bash
    echo 127.0.0.1$'\t'$HOSTNAME | sudo tee -a /etc/hosts

    # OS settings
    sudo sysctl -w kern.sysv.shmmax=2147483648
    sudo sysctl -w kern.sysv.shmmin=1
    sudo sysctl -w kern.sysv.shmmni=64
    sudo sysctl -w kern.sysv.shmseg=16
    sudo sysctl -w kern.sysv.shmall=524288
    sudo sysctl -w net.inet.tcp.msl=60

    sudo sysctl -w net.local.dgram.recvspace=262144
    sudo sysctl -w net.local.dgram.maxdgram=16384
    sudo sysctl -w kern.maxfiles=131072
    sudo sysctl -w kern.maxfilesperproc=131072
    sudo sysctl -w net.inet.tcp.sendspace=262144
    sudo sysctl -w net.inet.tcp.recvspace=262144
    sudo sysctl -w kern.ipc.maxsockbuf=8388608

    sudo tee -a /etc/sysctl.conf << EOF
    kern.sysv.shmmax=2147483648
    kern.sysv.shmmin=1
    kern.sysv.shmmni=64
    kern.sysv.shmseg=16
    kern.sysv.shmall=524288
    net.inet.tcp.msl=60

    net.local.dgram.recvspace=262144
    net.local.dgram.maxdgram=16384
    kern.maxfiles=131072
    kern.maxfilesperproc=131072
    net.inet.tcp.sendspace=262144
    net.inet.tcp.recvspace=262144
    kern.ipc.maxsockbuf=8388608
    EOF

    # Step: Configure
    cat >> ~/.bashrc << EOF
    ulimit -n 65536 65536  # Increases the number of open files
    export PGHOST="$(hostname)"
    EOF
    ```

    4. fix PYTHONPATH in greenplum-env.sh (installed by brew) to use system python, something like
    echo export PYTHONPATH=$(pip show psutil | grep Location | awk '{print $2}'):\\\$PYTHONPATH >> #{prefix}/greenplum_path.sh

    5. start a GPDB demo cluster using following command
    source #{prefix}/greenplum_path.sh
    cd #{prefix}
    make -C demo
    source demo/gpdemo-env.sh

    6. test it out
    createdb
    psql
    EOS
  end

  test do
    system "createdb", "test"
    system "dropdb", "test"
  end
end
