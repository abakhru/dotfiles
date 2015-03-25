#!/usr/bin/env python

import os
import sys
import time
import unittest

from selenium import selenium
from selenium import webdriver
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.common.keys import Keys
from ctf.framework.logger import LOGGER
from eTest.xml.project import XMLProjectParser
from rsa.netwitness.web.web_helper import *
from ctf.framework import testcase

LOGGER.setLevel('DEBUG')
CORRELATION_PANEL_NAME = 'correlation-group-panel'

"""
class Test_5f_1s_correlation(ESABaseTest):
    def execute(self):
        try:
            common = CommonAction()
            common.login()
            esa_actions_obj = esa_actions()
            # Go to the config page of ESA
            alerting_page = common.goto_alerting_page()
            name = 'module_name_5f_1s_correlation'
            params = {'name': name, 'desc': 'this is basic rule', 'severity': 'Low', 'occurs': '2'}

            build_param = {'stmt_name': '5F', 'stmt_cond': 'if all conditions are met',
                           'meta_key': 'ec_activity', 'eval_type': 'is', 'value': 'Logon'}

            status = esa_actions_obj.create_basic_rule(rule_params=params, build_param=build_param)
            self.assertTrue(status, True,
                            **{"assertMessage": 'Rule Statement created successfully'})

            deletion_status = esa_actions_obj.delete_module([name])
            self.assertTrue(deletion_status, True,
                            **{"assertMessage": 'ESA basic rule successfully deleted'})

        except Exception as e:
            self.status = False
            self.log.error("Exception Found while Test Execution %s" % e)

    def validate(self):
        self.assertTrue(self.status)
"""


class AddCorrelationDevice(object):

    def __init__(self):
        for row in self.browser.find_elements_by_class_name('x-grid-with-row-lines'):
            if 'NameSynchronization' in row:
                LOGGER.debug('We are in Add Device Popup with Name & Synchronization as headers')
                return True
        return False

    def select_service_dev(self, dev_name):
        """
        Selecting a device
        @param dev_list: Accepts the list of devices to be selected,selects all if list is empty
        """
        LOGGER.info('Selecting \'%s\' ESA device', dev_name)
        if self.is_device_present_in_popup:
            for row in self.browser.find_elements_by_class_name('x-grid-cell-inner'):
                if row.text == dev_name:
                    row.click()
                    break
            return True
        return False

    def click_on_footer_option(self, option):
        """
        Clicks on Cancel/Save
        """
        LOGGER.info('Clicking \'%s\' button', option)
        # self.browser.find_element_by_xpath("//button[contains(.,'Save')]")
        for footer in self.browser.find_elements_by_class_name('x-toolbar-footer'):
            for button in footer.find_elements_by_tag_name('button'):
                if button.text == option:
                    button.click()
                    break
            break

    def is_device_present_in_popup(self, dev_name):
        """
        Returns true or false whether the device is present in the add popup or none
        """
        for row in self.browser.find_elements_by_class_name('x-grid-cell-inner'):
            if row.text == dev_name:
                LOGGER.debug("Found device : %s" % dev_name)
                return True
        LOGGER.error("Unable to find the following device : %s" % dev_name)
        return False


class SATestCase(testcase.TestCase
                 , AddCorrelationDevice):

    def setUp(self):
        super(SATestCase, self).setUp()
        self._readProjectFile()
        self.browser = webdriver.Firefox()
        self.base_url = self.get_base_url()
        #self.addCleanup(self.browser.quit)
        self.browser.get(self.base_url + '/login')
        self.browser.maximize_window()
        time.sleep(5)
        self.accept_eula()
        self.login()
        self.goto_alerting_page()
        self.correlation_panel_id = self.browser.find_element_by_id(CORRELATION_PANEL_NAME)
        self.correlation_panel_body = self.browser.find_element_by_id(CORRELATION_PANEL_NAME
                                                                      + '-body')

    def _readProjectFile(self):
        try:
            parser = XMLProjectParser('.', 'etfproject.xml')
        except:
            sys.stderr.write('ERROR: Error parsing project file.')
            LOGGER.error(sys.exc_info()[1])
        else:
            # get the properties
            properties = parser.getProperties()
            keys = properties.keys()
            keys.sort()
            for key in keys: setattr(self, key, properties[key])
            parser.addToPath()
            parser.unlink()
            LOGGER.debug('SA hostname: %s', self.ReportingUIHost)
            #PROJECT.ESA = self.ESA

    def accept_eula(self):
        """
        Accept the end user agreement if present.
        """
        LOGGER.debug('Accepting the End User License Agreement...')
        self.browser.find_element_by_id('accept-eula-button-btnEl').click()

    def get_base_url(self):
        self.ip = self.ReportingUIHost
        self.port = self.ReportingUIPort
        self.proto = self.ReportingUIProtocol
        base_url = self.proto + '://' + self.ip + ':' + self.port
        return base_url

    def assertPageTitle(self, title='RSA Security Analytics Login'):
        LOGGER.debug('Browser Title : %s', self.browser.title)
        self.assertIn(title, self.browser.title)

    def login(self):
        self.assertPageTitle()
        self.elem = self.browser.find_element_by_name('j_username')
        self.elem.send_keys('admin' + Keys.RETURN)
        self.elem = self.browser.find_element_by_name('j_password')
        self.elem.send_keys('netwitness' + Keys.RETURN)
        time.sleep(3)
        LOGGER.debug('Browser Title: %s', self.browser.title)
        self.assertPageTitle('[UNF] \"Default\" Dashboard')
        LOGGER.info('Login successfully..')

    def goto_alerting_page(self):
        self.browser.get(self.base_url + '/alerting/configure')
        time.sleep(5)
        self.assertPageTitle('[ALRT] Configure')

    def correlation_panel_header(self):
        """
        Make this assert
        """
        self.coorelation_panel_header = self.browser.find_element_by_id(CORRELATION_PANEL_NAME
                                                                 + '_header_hd')
        self.assertTrue(self.coorelation_panel_header.is_displayed())
        LOGGER.debug('Correlation Panel Header: %s', self.coorelation_panel_header.text)
        self.assertEquals('CORRELATION GROUPS', self.coorelation_panel_header.text)

    def click_correlation_option(self, option=None):
        """
        clicks on Add/Edit/Delete/Refresh in Correlation dropdown menu
        """
        if option.lower() == "add":
            select_option = 0
        if option.lower() == "delete":
            select_option = 1
        if option.lower() == "edit":
            select_option = 2
        if option.lower() == "refresh":
            select_option = 3
        elem_list = self.browser.find_elements_by_class_name('x-menu-item-link')
        for elem in elem_list:
            LOGGER.debug('Elem text: %s', elem.text)
            if elem.text.lower() == option.lower():
                elem.click()
                break
        #self.browser.find_element_by_class_name('x-menu-item-link')[select_option].click()
        return

    def execute_javascript(self, script, time_out=30):
        """
        Private method
        Executes the specified JavaScript on the browser using the WebDriver(browser) object
        """
        LOGGER.debug('Executing JavaScript... %s' % script)
        lookup_time = 0
        while lookup_time <= time_out:
            try:
                response = self.browser.execute_script("%s" % script)
                LOGGER.debug("JavaScript Execution Response:%s" % response)
                return response
            except:
                if lookup_time == 0:
                    LOGGER.debug("JavaScript Execution Failed!! Waiting for 1 more second to load if the "
                              "element is not loaded..")
                    LOGGER.debug("JavaScript will be re-executed till the element loaded or the timeout "
                              "'%s'seconds reached.." % time_out)
            sleep(1)
            lookup_time += 1
        LOGGER.critical("JavaScript Exception occurred with the following JavaScript:")
        LOGGER.critical("%s" % script)
        e = sys.exc_info()[1]
        message = "Exception while Executing JS %s" % e
        raise NoSuchElementException(message)

    def get_id(self, itemid="", flag=0):
        try:
            return self.execute_javascript("return Ext.ComponentQuery.query('#%s')[%s].id"
                                           % (itemid, flag))
        except:
            raise NoSuchElementException("No such 'Item Id' Found!")

    def get_webelement(self, locator, time_out=30):
        """
        Returns an WebDriver element object
        @param locator: Locator to find an element. If the locator is not unique it may return the
        first element found!
         Supported Locators are
            id - id of the element
            name - name of the element
            css - A unique element identifier using CSS
            xpath -A unique element identifier using XPATH
            classname - A unique identifier using classname
            tagname - A unique identifier usingHTML tagname
            javascript - A unique identifier using javascript to find the element
        """
        try:
            self.browser.implicitly_wait(time_to_wait=0)
            LOGGER.debug("WebDriver is trying to find WebElement with locator:%s" % locator)
            lookup_time = 0
            while lookup_time < time_out:
                if isinstance(locator, WebElement):
                    LOGGER.debug("Locator was a WebElement")
                    return locator
                try:
                    element = self.browser.find_element_by_id(locator)
                    LOGGER.debug("Locator is ID Returning Element")
                    return element
                except (NoSuchElementException, WebDriverException):
                    msg = 'Locator %s is not ID' % locator
                    # LOGGER.debug(msg)
                try:
                    element = self.browser.find_element_by_name(locator)
                    LOGGER.debug("Locator is NAME Returning Element")
                    return element
                except (NoSuchElementException, WebDriverException):
                    msg = 'Locator %s is not NAME' % locator
                    # LOGGER.debug(msg)
                try:
                    element = self.browser.find_element_by_css_selector(locator)
                    LOGGER.debug("Locator is CSS Returning Element")
                    return element
                except (NoSuchElementException, WebDriverException):
                    msg = 'Locator %s is not CSS' % locator
                    # LOGGER.debug(msg)
                try:
                    element = self.browser.find_element_by_xpath(locator)
                    LOGGER.debug("Locator is XPATH Returning Element")
                    return element
                except (NoSuchElementException, WebDriverException):
                    msg = 'Locator %s is not XPATH' % locator
                    # LOGGER.debug(msg)
                try:
                    element = self.browser.find_element_by_class_name(locator)
                    LOGGER.debug("Locator is ClassName Returning Element")
                    return element
                except (NoSuchElementException, WebDriverException):
                    msg = 'Locator %s is not ClassName' % locator
                    # LOGGER.debug(msg)
                try:
                    element = self.browser.find_element_by_tag_name(locator)
                    LOGGER.debug("Locator is TagName Returning Element")
                    return element
                except (NoSuchElementException, WebDriverException):
                    msg = 'Locator %s is not TagName' % locator
                    # LOGGER.debug(msg)
                try:
                    if 'document.get' in locator or 'Ext.get' in locator:
                        LOGGER.debug("Locator is JS executing it to get web element..")
                        element = execute_javascript(script="return %s" % locator)
                        return element
                except (NoSuchElementException, WebDriverException):
                    msg = 'Locator %s is not JS' % locator
                    # LOGGER.debug(msg)
                LOGGER.debug("Unable to find Element waiting for 1 more second to load it..")
                sleep(1)
                lookup_time += 1
        except Exception:
            raise NoSuchElementException("NoSuchElementFound: Unable To Find an element with the "
                                         "locator %s provided" % locator)
        finally:
            self.browser.implicitly_wait(time_to_wait=30)

    def type_correlation_group_name(self, name):
        """
        Types the coorelation group name in input field
        """
        LOGGER.debug('Typing Correlation name')
        input_elements = self.browser.find_elements_by_tag_name('input')
        LOGGER.debug('List of all input elements: %s', input_elements)
        self.browser.switch_to.active_element.send_keys(name + Keys.RETURN)
        time.sleep(2)

    def get_xsite_group_names(self):
        """
        returns a list containing crorrelation group names
        """
        xsite_len = self.execute_javascript("return Ext.getCmp('%s').getStore().data.items.length"
                                            % CORRELATION_PANEL_NAME)
        if not xsite_len:
            LOGGER.debug("There are 0 correlation groups present, trying again after few seconds")
            time.sleep(3)
            xsite_len = self.execute_javascript("return Ext.getCmp('%s').getStore("
                                                ").data.items.length" % CORRELATION_PANEL_NAME)
        xsite_list = []
        for i in range(0, xsite_len):
            xsite_list.append(self.execute_javascript("return Ext.getCmp('%s').getStore().data."
                                                      "items[%s].data.name"
                                                      % (CORRELATION_PANEL_NAME, i)))
        LOGGER.info('Current correlation groups list : %s', xsite_list)
        return xsite_list

    def select_xsite_group(self, xsite_name):
        """
        select a crorrelation group
        """
        LOGGER.info("Selecting the correlation group named : \'%s\'" % xsite_name)
        self.assertIn(xsite_name, self.get_xsite_group_names)
        try:
            self.browser.find_element_by_xpath("//td[contains(.,'%s')]" % xsite_name).click()
            return True
        except Exception as e:
            LOGGER.error('Correlation Group \'%s\' not found: %s', e)
            return False

    def add_correlation_group(self, group_name):
        """ Creates a Correlation Group with provided group name"""
        LOGGER.info('Creating a correlation group named : %s', group_name)
        try:
            self.correlation_panel_id.find_element_by_class_name('x-btn-icon').click()
            self.browser.find_element_by_link_text('Add').click()
            time.sleep(6)
            self.browser.switch_to.active_element.send_keys(group_name + Keys.RETURN)
        except Exception as e:
            LOGGER.error('Something failed during correlation group creation')
            LOGGER.error(e)
            return False
        LOGGER.info('Correlation panel body : %s', self.correlation_panel_body.text)
        self.assertIn(group_name, self.correlation_panel_body.text)
        LOGGER.info('Correlation group \'%s\' created successfully', group_name)
        time.sleep(1)
        return True

    def delete_correlation_group(self, group_name):
        """ Creates a Correlation Group with provided group name"""
        LOGGER.info('Deleting a correlation group named : %s', group_name)
        try:
            self.select_xsite_group(group_name)
            self.correlation_panel_id.find_element_by_class_name('x-btn-icon').click()
            self.browser.find_element_by_link_text('Delete').click()
            time.sleep(3)
        except Exception as e:
            LOGGER.error('Something failed during correlation group deletion')
            LOGGER.error(e)
            return False
        LOGGER.info('Correlation panel body : %s', self.correlation_panel_body.text)
        self.assertNotIn(group_name, self.correlation_panel_body.text)
        LOGGER.info('Correlation group \'%s\' deleted successfully', group_name)
        time.sleep(1)
        return True

    def _print_webelement_details(self, elem):
        LOGGER.debug('element active attribute value: %s', elem.get_attribute('class'))
        LOGGER.debug('elem dic: %s', elem.rect)
        LOGGER.debug('elem parent: %s', elem.parent)
        LOGGER.debug('elem location: %s', elem.location)
        LOGGER.debug('elem is_enabled : %s', elem.is_enabled())
        return

    def test_correlation_group_creation(self):
        self.add_correlation_group(self.test_name)
        self.assertIn(self.test_name, self.get_xsite_group_names)
        self.delete_correlation_group(self.test_name)

    def test_add_correlation_group_services(self):
        self.add_correlation_group()
        self.select_xsite_group('test_create_correlation_group')
        time.sleep(5)
        labels_list = self.browser.find_elements_by_class_name('body-panel-white-text')
        for label in labels_list:
            if label.text == 'Correlate Services':
                LOGGER.info('Correlate Services header found')
            if label.text == 'Correlate Rules':
                LOGGER.info('Correlate Rules header found')
        self.browser.find_elements_by_class_name('icon-add')[0].click()
        time.sleep(3)
        xsite_add_service_panel_id = self.browser.find_element_by_class_name('x-window-header-text-default')
        self.assertEquals('Synchronize ESA Services', xsite_add_service_panel_id.text)
        self.select_service_dev(self.ESAUIName)
        self.click_on_footer_option('Save')
        time.sleep(7)
        for row in self.browser.find_elements_by_class_name('x-grid-row'):
            LOGGER.debug('==== Current Row: \"%s\"', row.text)
            if self.ESA in row.text:
                self.assertIn('Added', row.text)
                self.assertIn(self.ESAUIName, row.text)
                self.assertIn(self.ESA, row.text)

        LOGGER.info('Clicking Synchronize button')
        self.browser.find_element_by_xpath("//button[contains(.,'Synchronize')]")
        #self.assertIn('1', self.correlation_panel_body.text)
        print self.browser.title
        self.delete_correlation_group()

    def test_save_before_adding_correlation_devices(self):
        """ If Save button is clicked before ESA devices are selected, error should be shown.

        Expectation is 'Select ESA service(s)' alert message will be displayed in add device window"
         """
        self.add_correlation_group(self.test_name)
        self.select_xsite_group('test_create_correlation_group')
        self.browser.find_elements_by_class_name('icon-add')[0].click()
        time.sleep(3)
        self.click_on_footer_option('Save')
        self.assertEquals('Select ESA service(s)'
                          , self.browser.find_element_by_class_name('x-form-invalid-under').text)
        self.delete_correlation_group(self.test_name)

    #def test_add_correlation_group_rules(self):
        #self.browser.find_elements_by_class_name('icon-add')[1].click()
        #self.browser.runScript(with (Ext.getCmp('genderComboBox')) { setValue('Add'); fireEvent('select'); })
        #LOGGER.debug('IWebElement : %s', AddGroup)

    def tearDown(self):
        self.browser.close()


class Addsyncrules(object):
    def __init__(self):
        grid_len = execute_javascript("return document.getElementsByClassName('x-panel "
                                      "x-grid-with-row-lines x-fit-item x-panel-default "
                                      "x-grid').length")
        for i in range(grid_len):
            if "StatusRule NameSeverity" in execute_javascript("return "
                                                               "document.getElementsByClassName("
                                                               "'x-panel x-grid-with-row-lines "
                                                               "x-fit-item x-panel-default "
                                                               "x-grid')[%s].textContent" % i):
                self.sync_pop_id = execute_javascript("return document.getElementsByClassName("
                                                      "'x-panel x-grid-with-row-lines x-fit-item "
                                                      "x-panel-default x-grid')[%s].id" % i)
                break

    def select_synchronize_rule(self, rule_name):
        """
        Selects the rule added to the respective synchronization.
        @param rule_list:list of rule(s) to be selected, selects all if list is empty
        """
        LOGGER.debug("selecting the following rule(s) %s" % rule_name)

        index = execute_javascript("return Ext.getCmp('%s').getStore().find('name','%s')"
                                   % (self.sync_pop_id, rule_name))
        if index == -1:
            LOGGER.debug('rule %s is not present' % rule_name)
            return False
        LOGGER.debug("Found val :%s at position:%s.selecting it" %
                  (rule_name, index))
        execute_javascript('Ext.getCmp("%s").getSelectionModel().select(%s,"True")'
                           % (self.sync_pop_id, index))

    def click_on_footer_option(self, option):
        """
        clicks on Cancel/Save
        """
        footer_len = execute_javascript("return document.getElementsByClassName('x-toolbar "
                                        "x-docked x-toolbar-footer').length")
        for i in range(footer_len):
            if "CancelSave" in execute_javascript("return document.getElementsByClassName("
                                                  "'x-toolbar x-docked x-toolbar-footer')["
                                                  "%s].textContent" % i):
                break

        buttons_len = execute_javascript("return document.getElementsByClassName('x-toolbar "
                                         "x-docked x-toolbar-footer')[%s].getElementsByTagName("
                                         "'button').length" % i)
        for j in range(buttons_len):
            if option == execute_javascript("return document.getElementsByClassName('x-toolbar "
                                            "x-docked x-toolbar-footer')[%s].getElementsByTagName"
                                            "('button')[%s].textContent" % (i, j)):
                execute_javascript("document.getElementsByClassName('x-toolbar x-docked "
                                   "x-toolbar-footer')[%s].getElementsByTagName('button')["
                                   "%s].click()" % (i, j))
                break

    def is_rule_present_in_popup(self, rule_name):
        """
        Returns true or false whether the rule is present in the add popup or not
        """
        found = execute_javascript("return Ext.getCmp('%s').getStore().find('displayName','%s')"
                                   % (self.sync_pop_id, rule_name))
        if found == -1:
            LOGGER.debug("Unable to find the following rules:%s" % rule_name)
            return False
        else:
            LOGGER.debug("Found rule :%s at position:%s." % (rule_name, found))
            return True


if __name__ == '__main__':
    unittest.main(verbosity=2)
