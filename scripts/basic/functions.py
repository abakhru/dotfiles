#!/usr/bin/env python

class FunctionTrials(object):
    @property
    def list_of_benefits(self):
        return self.__list_of_benefits

    def __init__(self):
        self.__list_of_benefits = []

    # Modify this function to return a list of strings as defined above
    def list_benefits(self):
        benefits1 = ["More organized code", "More readable code", "Easier code reuse"]
        self.__list_of_benefits.append(benefits1)
        benefits2 = ["Allowing programmers to share and connect code together"]
        self.__list_of_benefits.append(benefits2)

    # Modify this function to concatenate to each benefit - " is a benefit of functions!"
    def build_sentence(self):
        print
        self.list_of_benefits
        for benefit in self.list_of_benefits:
            print
            benefit
            print
            '****'

    def name_the_benefits_of_functions(self):
        list_of_benefits = list_benefits()
        build_sentence(list_of_benefits)


if __name__ == '__main__':
    a = FunctionTrials()
    a.list_benefits()
    a.build_sentence()
