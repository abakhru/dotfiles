phonebook = {
    "John" : 938477566,
    "Jack" : 938377264,
    "Jill" : 947662781
}

del phonebook["Jill"]
phonebook["Jake"] = 938273443

for name, number in phonebook.iteritems():
	print "Phone number of %s is %d" % (name, number)

# Handle all the exceptions!
#Setup
actor = {"name": "John Cleese", "rank": "awesome"}

#Function to modify, should return the last name of the actor - think back to previous lessons for how to get it
def get_last_name():
	try:
		for name, first_name in actor.iteritems():
			names = split(first_name)
			print "First Name : %s & Last Name : %s " % (names[0], names[1])
    		return names[1]
	except NameError:
        	print "name 'last_name' is not defined"


#Test code
get_last_name()
print "All exceptions caught! Good job!"
print "The actor's last name is %s" % get_last_name()
