# fill in this function
def fib():
    a, b = 0, 1
    # for _ in xrange(n):
    while True:
        yield a
        a, b = b, a + b


# testing code
import types

if type(fib()) == types.GeneratorType:
    print
    "Good, The fib function is a generator."

    counter = 0
    for n in fib():
        print
        n
        counter += 1
        if counter == 10:
            break
