.PHONY: all
all:

.PHONY: setup
setup:
	echo "deb http://debian.saltstack.com/debian wheezy-saltstack-2014-07 main" > /etc/apt/sources.list.d/salt.list
	apt-get update -y
	apt-get install -y salt-common msgpack-python python-git python-zmq

.PHONY: develop
develop:
	test -d /etc/salt/minion.d/ || mkdir /etc/salt/minion.d/
	for f in $$(find minion.d -name "*.conf") ; do \
		sed "s,PWD,$$(pwd),g" $$f > /etc/salt/$$f ; \
	done
