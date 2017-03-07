# change this code
number = 16
second_number = 0
first_array = [1, 2, 3]
second_array = [1, 2]

if number > 15:
    print
    "1"

if first_array:
    print
    "2"

if len(second_array) == 2:
    print
    "3"

if len(first_array) + len(second_array) == 5:
    print
    "4"

if first_array and first_array[0] == 1:
    print
    "5"

if not second_number:
    print
    "6"

# for i in first_array:
#	print "==== %d ====" % i

even = 0
odd = 0
for i in xrange(1, 11):
    if (i % 2 == 0): even = even + i
    if (i % 2 != 0): odd = odd + i
    print
    "==== %d ====" % i

print
"EVEN SUM = %d" % even
print
"ODD SUM = %d" % odd

numbers = [
    951, 402, 984, 651, 360, 69, 408, 319, 601, 485, 980, 507, 725, 547, 544,
    615, 83, 165, 141, 501, 263, 617, 865, 575, 219, 390, 984, 592, 236, 105, 942, 941,
    386, 462, 47, 418, 907, 344, 236, 375, 823, 566, 597, 978, 328, 615, 953, 345,
    399, 162, 758, 219, 918, 237, 412, 566, 826, 248, 866, 950, 626, 949, 687, 217,
    815, 67, 104, 58, 512, 24, 892, 894, 767, 553, 81, 379, 843, 831, 445, 742, 717,
    958, 609, 842, 451, 688, 753, 854, 685, 93, 857, 440, 380, 126, 721, 328, 753, 470,
    743, 527
]

for i in numbers:
    if (i % 2 == 0): print
    "%d" % i
    if (i == 237): break
