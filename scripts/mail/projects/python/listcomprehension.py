sentence = "the quick brown fox jumps over the lazy dog"
words = sentence.split()
print words
word_lengths = [len(word) for word in words if word != "the"]
print word_lengths

numbers = [34.6, -203.4, 44.9, 68.3, -12.2, 44.6, 12.7]
newlist = [num for num in numbers if num > 0]

print newlist
