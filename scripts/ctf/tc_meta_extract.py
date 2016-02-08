import importlib
import inspect
import json
import os
import sys
import xlsxwriter

from framework.common.logger import LOGGER
from xlsxwriter.utility import xl_rowcol_to_cell


class TestCaseMetaExtract(object):
    """ Class for extracting meta data from test class/test module/test case


    Note:  Script Usage -- cd unify; export PYTHONPATH=`pwd`;
           python ../tools/tc_meta_extract.py frontend/esa/test/basic_rule_test.py
    """

    XL_SHEET_COLS = ['Subject', 'Type of Test', 'Test Name', 'Description', 'Priority', 'Step Name'
                     , 'Steps of Execution', 'Expected Result', 'Component', 'Scrum'
                     , 'Version introduced', 'TC Status', 'Automation Status']
    ALL_FINAL_DATA_TO_WRITE = list()
    CLASS_QC_DATA = dict()

    def create_testcase_data(self, code_const):
        """This method parses Description and all other relevant keys from test method

        and returns a dictionary related to the test method

        Args:
            code_const: code object const for the test function(tuple)

        Returns:
            qc data relevant to the test method (dict)
        """
        test_method_data = dict()
        test_method_data['Description'] = code_const[0]
        all_data = code_const[::-1]
        for i in range(1, len(all_data) - 2):
            test_method_data[all_data[i]] = all_data[i + 1]
            i += 2
        return test_method_data

    def extract_all_data(self, file_path=None):
        """This method scrapes all the data from the file and returns the data

        that can be written to file

        Args:
            file_path: Path to test file (str)
        """

        mod_dir = os.path.dirname(file_path)
        mod_dir = mod_dir.replace('/', '.')
        mod_name = '.'.join(os.path.basename(file_path).split('.')[:-1])
        full_module_name = mod_dir + '.' + mod_name
        imported_module = importlib.import_module(full_module_name)
        LOGGER.debug('Imported Module: %s', imported_module)
        current_class = ''

        LOGGER.debug('Getting appropriate class')
        all_classes = inspect.getmembers(imported_module, inspect.isclass)
        for cls in all_classes:
            if cls[1].__module__ == full_module_name:
                current_class = cls[1].__name__

        LOGGER.debug('Instantiate the class')
        LOGGER.debug('imported_module: %s', imported_module)
        LOGGER.debug('current_class: %s', current_class)
        class_ = getattr(imported_module, current_class)
        current_class_inst = class_()
        self.CLASS_QC_DATA = getattr(class_, 'test_qc_data')

        LOGGER.debug('Getting all the test_ functions from the class')
        all_functions = inspect.getmembers(class_, inspect.isfunction)
        functions_of_interest = [func for func in all_functions if func[0].startswith('test_')]
        LOGGER.debug('functions_of_interest: %s', functions_of_interest)

        LOGGER.debug('Now parse the functions to generate the final data')
        all_qc_data = list()

        # test case qc extraction loop
        for funcs in functions_of_interest:

            current_test_func_dict = getattr(current_class_inst, funcs[0]).__dict__
            common_class_qc_data = self.CLASS_QC_DATA
            _obj = current_class_inst
            current_test_func = funcs[0]
            try:
                getattr(_obj, current_test_func)()
            except AttributeError:
                pass
            LOGGER.debug('Calling TestCase.SetQcDataFunction')
            code_obj = getattr(_obj, current_test_func).__code__
            test_case_specific_data = self.create_testcase_data(code_obj.co_consts)

            try:
                all_vars_in_class = inspect.getmembers(current_class_inst)
                if any('test_qc_data' in vv for vv in all_vars_in_class):
                    set_qc_data_func = getattr(current_class_inst, 'SetQcData')
                    set_qc_data_func(data=test_case_specific_data, common=common_class_qc_data)
                else:
                    set_qc_data_func = getattr(current_class_inst, 'SetQcData')
                    set_qc_data_func(data=test_case_specific_data, common=common_class_qc_data
                                     , nodata=True)
            except AttributeError:
                LOGGER.error('Error while calling setQcData')

            LOGGER.debug('Now we get the variable initialized as we want')
            try:
                test_qc_data = getattr(current_class_inst, 'test_qc_data')
            except Exception:
                test_qc_data = getattr(current_class_inst, 'test_data')
            LOGGER.debug('Setting the Test Name key to: %s', current_test_func)
            test_qc_data['Test Name'] = current_test_func

            # TODO: bakhra: Uncomment the below line to extract docstring from test method,
            # once the python bug is resolved https://bugs.python.org/issue24024
            # test_qc_data['Description'] = inspect.getdoc(current_test_func)

            list_of_all_dec = list()
            temp_list_of_all_dec = list()
            is_automation_status_set = False
            is_tc_status_set = False

            LOGGER.debug('Setting Automation Status and TC Status')

            if len(current_test_func_dict) > 0:
                for vals in current_test_func_dict.keys():
                    list_of_all_dec.extend([vals])

            if 'manual' in list_of_all_dec:
                test_qc_data['Automation Status'] = 'manual'
                is_automation_status_set = True
            for key in list_of_all_dec:
                if key == 'manual':
                    continue
                else:
                    temp_list_of_all_dec.extend([key])
            if len(temp_list_of_all_dec) == 0:
                test_qc_data['TC Status'] = 'ready'
                is_tc_status_set = True
            else:
                test_qc_data['TC Status'] = str(temp_list_of_all_dec)
                is_tc_status_set = True

            if len(list_of_all_dec) == 0 or temp_list_of_all_dec == list():

                if is_tc_status_set is False:
                    test_qc_data['TC Status'] = 'ready'
                if is_automation_status_set is False:
                    test_qc_data['Automation Status'] = 'Automated'

            if 'Automation Status' not in test_qc_data:
                test_qc_data['Automation Status'] = 'Automated'

            LOGGER.debug('Setting the Subject as class name.')
            test_qc_data['Subject'] = current_class

            to_insert = test_qc_data.copy()
            all_qc_data.extend([to_insert])
            LOGGER.debug('Delete keys so that we reset data for next test Method')
            for key in test_case_specific_data:
                if key in test_qc_data:
                    del test_qc_data[key]
            LOGGER.debug('[TestCaseMetaExtract] FINAL test_qc_data for %s:\n%s'
                         , current_test_func, self._pretty_print_dict(to_insert))
        return all_qc_data

    def _pretty_print_dict(self, _dict):
        return json.dumps(_dict, sort_keys=True, indent=4, separators=(',', ': '))

    def write_to_file(self, all_qc_data):
        """This method writes all data to xls file

        Args:
            all_qc_data: Detailed data dictionary to write to (dict)
        """
        file_name = 'unite_all_tests.xlsx'
        if os.path.isfile(file_name):
            LOGGER.info('File %s exists.. Removing it first', file_name)
            os.remove(file_name)
        workbook = xlsxwriter.Workbook(file_name)
        worksheet = workbook.add_worksheet()

        LOGGER.debug('Write the headings first')
        start_row_index = 8
        xl_list_index = 0
        for idx in range(len(self.XL_SHEET_COLS)):
            worksheet.write(xl_rowcol_to_cell(start_row_index, idx)
                            , self.XL_SHEET_COLS[xl_list_index])
            xl_list_index += 1
        current_row_for_dict = 0
        LOGGER.debug('Now write actual data')
        for test_data in all_qc_data:
            col_idx = 0
            start_row_idx_for_value = 11 + current_row_for_dict
            for data in test_data:
                current_test_data_dict = data
                for key in self.XL_SHEET_COLS:
                    if key == 'Error Method':
                        continue
                    if key in ['Step Name', 'Steps of Execution', 'Expected Result']:
                        col_idx += 1
                        continue
                    current_value = current_test_data_dict[key]
                    worksheet.write(xl_rowcol_to_cell(start_row_idx_for_value, col_idx)
                                    , current_value)
                    col_idx += 1
                start_row_idx_for_value += 1
                col_idx = 0
            current_row_for_dict += len(test_data)
        workbook.close()

    def validate_data(self, all_data_to_write):
        """This method checks if we have all the required data we need for writing to file

        Args:
            all_data_to_write:- Dictionary of all values that are to be written to xls file (dict)

        Returns:
            List of all error methods that need to be addressed by the developer
        """

        all_errors = dict()
        accepted_missing_keys = ['Step Name', 'Steps of Execution', 'Expected Result']

        for data in all_data_to_write:
            if len(data) < len(self.XL_SHEET_COLS):
                all_missing_keys = [x for x in list(data.keys())
                                    if x not in (self.XL_SHEET_COLS + accepted_missing_keys)]
                LOGGER.debug('all_missing_keys for %s: %s'
                             , data['Test Name'], all_missing_keys)
        LOGGER.debug('All errors: %s', all_errors)
        return all_errors

    def Main(self, file_path=None):
        """This method performs all the importing and extracting of data needed to write to the file

        Args:
            file_path: Path to the *_test.py file (str)

        Raises:
            Exception: if required values are not found

        Note:
            https://wiki.na.rsa.net/display/ASOCWEST/Test+Case+Extraction+Tool
        """

        LOGGER.debug('Import modules that we need and extract data')
        all_data_to_write = self.extract_all_data(file_path)
        all_errors = self.validate_data(all_data_to_write)
        if not len(all_errors):
            LOGGER.debug('No errors found. Writing to file...')
            self.ALL_FINAL_DATA_TO_WRITE.extend([all_data_to_write])
        else:
            LOGGER.error('The following required values are missing :')
            for key in all_errors:
                LOGGER.error('%s: %s', key, all_errors[key])
            raise Exception('Required values missing!! Aborting run!!')

    def get_all_test_files(self, all_base_dir_paths):
        """This method scans all the directories that are passed in and returns all the test

        modules that can be used to extract the intended variable

        Args:
            all_base_dir_paths: base paths to all the test directories (list)

        Returns:
            Paths to all test files (list)
        """

        all_file_paths = list()
        for basedir in all_base_dir_paths:
            all_file_paths += [os.path.join(r, f) for r, d, fs in os.walk(basedir)
                               for f in fs if '_test.py' in f]
        LOGGER.debug('All test files: %s', all_file_paths)
        return all_file_paths

    def get_files_to_extract(self, all_command_line_args):
        """This method parses all the command line arguments that are passed and returns

        list of all the *_test.py files which are then used to extract the intended variable

        Args:
            all_command_line_args:- the command line args that are passed(list)
        Returns:
            paths to all the test modules(list)
        """

        all_directory_base_paths = list()
        all_paths_to_file = list()

        for arg in all_command_line_args:
            if os.path.isdir(arg):
                all_directory_base_paths.extend([arg])
            elif os.path.isfile(arg):
                current_file_path = arg
                split_file_path = current_file_path.rsplit('_', 1)[-1]
                if split_file_path == 'test.py':
                    all_paths_to_file.extend([arg])
                else:
                    LOGGER.error('Invalid file %s  is passed .Only *_test.py files are allowed.'
                                 ' Exiting...', current_file_path)
                    sys.exit(1)
        LOGGER.debug('All directory base paths: %s', all_directory_base_paths)
        if len(all_directory_base_paths) < 1 and len(all_paths_to_file) < 1:
            LOGGER.error('No test files available to read from the paths given. Exiting...')
            sys.exit(1)
        if len(all_directory_base_paths):
            all_paths_to_file.extend(self.get_all_test_files(all_directory_base_paths))

        LOGGER.debug('Final all_paths_to_file: %s', all_paths_to_file)
        return all_paths_to_file

    def extract_meta(self, _args):
        all_args = list()
        if len(_args) == 2:
            _args.append(os.getenv('PYTHONPATH'))
        LOGGER.debug('_args: %s', _args)
        for arg in _args:
            if '/' in arg or arg.endswith('_test.py'):
                if 'python' in arg or 'tc_meta_extract' in arg:
                    continue
            all_args.append(arg)
        LOGGER.debug('All interesting command line args: %s', all_args)
        if len(all_args) == 0:
            LOGGER.info('No arguments passed. Running script for both backend and frontend')
            all_args.append('backend')
            all_args.append('frontend')

        all_test_modules = self.get_files_to_extract(all_args)
        for testfile in all_test_modules:
            self.Main(testfile)
        if len(self.ALL_FINAL_DATA_TO_WRITE) is not 0:
            self.write_to_file(self.ALL_FINAL_DATA_TO_WRITE)

if __name__ == '__main__':
    t = TestCaseMetaExtract()
    t.extract_meta(_args=sys.argv)
