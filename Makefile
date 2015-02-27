.PHONY: all
all:

.PHONY: setup
setup:
	echo "deb http://debian.saltstack.com/debian wheezy-saltstack-2014-07 main" > /etc/apt/sources.list.d/salt.list
	apt-get update -y
	apt-get install -y salt-common msgpack-python python-git python-zmq

ROLE=jenkins-slave
RENDER=sed "s,PWD,$(shell pwd),g;s,ROLE,$(ROLE),g"
.PHONY: install-master
install-master:
	apt-get install -y salt-master
	test -d /etc/salt/master.d/ || mkdir /etc/salt/master.d/
	$(RENDER) etc/ci-salt.conf > /etc/salt/master.d/ci-salt.conf
	$(RENDER) etc/master.conf > /etc/salt/master.d/ci-salt-master.conf
	/etc/init.d/salt-master restart
	$(MAKE) install-minion ROLE=jenkins-master

.PHONY: install-minion
install-minion:
	apt-get install -y salt-minion
	test -d /etc/salt/minion.d/ || mkdir /etc/salt/minion.d/
	$(RENDER) etc/minion.conf > /etc/salt/minion.d/ci-salt-minion.conf
	/etc/init.d/salt-minion restart

.PHONY: develop-masterless
develop-masterless:
	test -d /etc/salt/minion.d/ || mkdir /etc/salt/minion.d/
	$(RENDER) etc/ci-salt.conf > /etc/salt/minion.d/ci-salt.conf
	$(RENDER) etc/masterless.conf > /etc/salt/minion.d/ci-salt-masterless.conf

.PHONY: uninstall
uninstall:
	rm -vf /etc/salt/minion.d/ci-salt*.conf
	rm -vf /etc/salt/master.d/ci-salt*.conf
