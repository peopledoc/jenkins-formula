=======================
 Jenkins provisionning
=======================

As super user:

.. code-block:: console

   ./bootstrap.sh
   make develop
   salt-call state.highstate

Jenkins is available at port 80: `<http://localhost/>`_
