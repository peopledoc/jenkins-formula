==============================
 Master-slave jenkins formula
==============================

This formula installs and configure master and slave nodes.

Available states
================

.. contents::
   :backlinks: none

`jenkins.master`
----------------

Install a jenkins instance with no executor and an SSH credential.

`jenkins.slave`
---------------

Register a dumb node on the master.

All states have a ``.uninstall`` relative states to (mostly) undo the
states. Beware, it erase all data !
