.PHONY: all
all:

.PHONY: setup
setup:
	echo "deb http://debian.saltstack.com/debian wheezy-saltstack-2014-07 main" > /etc/apt/sources.list.d/salt.list
	apt-get update -y
	apt-get install -y salt-common msgpack-python python-git python-zmq

RENDER=sed 's,PWD,$(shell pwd),g'
.PHONY: install
install:
	test -d /etc/salt/minion.d/ || mkdir /etc/salt/minion.d/
	$(RENDER) etc/ci-salt.conf > /etc/salt/minion.d/ci-salt.conf ;

.PHONY: develop
develop: install
	$(RENDER) etc/masterless.conf > /etc/salt/minion.d/ci-salt-masterless.conf ;

.PHONY: uninstall
uninstall:
	rm -vf /etc/salt/minion.d/ci-salt*.conf
