import pytest

from projects.markdown_adapter import run_markdown


@pytest.fixture(params=[
    # tuple with (input, expectedOutput)
    ('regular text', 'regular text</p>'),
    ('*em tags*', '<p><em>em tags</em></p>'),
    ('**strong tags**', '<p><strong>strong tags</strong></p>')
])
def test_data(request):
    return request.param


def test_markdown(test_data):
    (the_input, the_expected_output) = test_data
    the_output = run_markdown(the_input)
    print('\ntest_markdown():')
    print('  input   : %s' % the_input)
    print('  output  : %s' % the_output)
    print('  expected: %s' % the_expected_output)
    assert the_output == the_expected_output
