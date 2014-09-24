#!/usr/bin/env python

from ctf.framework import testcase

class UniversalConfTestCase(testcase.TestCase):
    """Tests that utilize a single universal conf.

    Universal conf (universal_conf.py) is located by checking in several places, starting with the
    test-specific data directory, followed by the test-case-specific data directory, the
    test-binary-specific data directory, and finally, the component test data directory.

    (1) testdata/<test_binary_name>/<test_case_name>/<test_name>/universal_conf.py
    (2) testdata/<test_binary_name>/<test_case_name>/universal_conf.py
    (3) testdata/<test_binary_name>/universal_conf.py
    (4) testdata/universal_conf.py

    The conf will contain symbols containing the values of most of the scalar properties of this
    test case.  For example, the 'test_data_dir' symbol contains the value of the test_data_dir
    property.

    A test has opportunities to modify the configuration.

    (1) The test case can override the ModifyConf method.  (If it does, it should call the
        superclass method before performing its own modifications.)

    (2) A method named ModifyConf_test_foo, if present, will be invoked during the setup of
        test_foo and presented with the conf to modify.  It should have the same signature as
        ModifyConf.

    Properties (available after setUp):
        conf_path: Path to the universal conf file (str).
        conf: Conf object read from conf_path (universal.ROOT).
    """

    @property
    def conf_path(self):
        return self.__conf_path

    # Optional to override:

    def ModifyConf(self, conf):
        """Override this to modify the base configuration for a test case.

        You may also define a ModifyConf_test_foo method to modify the configuration for test
        defined in the method test_foo.

        In addition, make sure the default number of threads used is always 1. Individual tests
        can override this using their own ModifyConf explicitly, if multi-threaded tests are
        called for.

        """
        print 'Inside PARENT ModifyConf'

    def setUp(self):
        testcase.TestCase.setUp(self)

        self.__conf_path = self.__GetConfPath()

        # Allow configuration modifications.
        self.__ModifyConf()

    @classmethod
    def GetConfProperties(cls):
        """Returns a list of properties of this class that will be saved as symbols in the conf.

        Returns:
            List of names of properties (list of str)
        """
        return [
            'test_binary_name',
            'test_case_name',
            'test_name',
            'test_id',

            'module_data_dir',
            'test_binary_data_dir',
            'test_case_data_dir',
            'test_data_dir',

            'module_knowngood_dir',
            'test_binary_knowngood_dir',
            'test_case_knowngood_dir',
            'test_knowngood_dir',

            'module_out_dir',
            'test_binary_out_dir',
            'test_case_out_dir',
            'test_out_dir',

            'conf_path',
            ]

    # Private:
    def __GetConfPath(self):
        """Locates the setup.cmds file based on the progression documented in this class."""
        dirs = [
                self.test_data_dir,
                self.test_case_data_dir,
                self.test_binary_data_dir,
                self.module_data_dir,
                ]
        conf_paths = [os.path.join(_dir, 'setup.cmds') for _dir in dirs]
        for conf_path in conf_paths:
            if os.path.exists(conf_path):
                LOGGER.debug('Found conf: %s', conf_path)
                return conf_path

        self.fail('Unable to locate setup.cmds, Tried %s' % ', '.join(conf_paths))

    def __ModifyConf(self):
        """Allow the hooks that modify the configuration to run."""
        # Test-case-specific hook.
        self.ModifyConf(self.conf)

        # Look for a test-specific hook.
        method_name = 'ModifyConf_%s' % self.test_name
        method = getattr(self, method_name, None)
        if method:
            method(self.conf)


class AbstractComponentTestCase(UniversalConfTestCase):

    def setUp(self):
        UniversalConfTestCase.setUp(self)
        print 'Inside AbstractComponentTestCase setUp'

    def test_basic(self):
        print 'Inside Test_basic'
        self.assertEqual(1, 1)

    def tearDown(self):
        UniversalConfTestCase.tearDown(self)
        print 'Inside AbstractComponentTestCase tearDown'


if __name__ == '__main__':
    p = AbstractComponentTestCase()
