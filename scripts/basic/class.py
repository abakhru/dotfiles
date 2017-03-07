# define the Vehicle class
class Vehicle:
    name = ""
    kind = "car"
    color = ""
    value = 100.00

    def description(self):
        desc_str = "%s is a %s %s worth $%.2f." % (self.name, self.color, self.kind, self.value)
        return desc_str


# your code goes here

MyCar1 = Vehicle()
MyCar2 = Vehicle()

MyCar1.name = "Fer"
MyCar1.kind = "convertible"
MyCar1.color = "red"
MyCar1.value = float("60000")

MyCar2.name = "Jump"
MyCar2.kind = "van"
MyCar2.color = "blue"
MyCar2.value = float("10000")

# checking code
print
MyCar1.description()
print
MyCar2.description()
