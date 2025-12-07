when defined(test):
    
    import std/unittest, ../debugging/checks, ../io/responses

    suite "Responses":
        test "isPositive":
            for word in ["yes", "y", "+", "ja", "oui", "yarp", "ye", "yep", ]:
                check word.isPositive() == true
            for word in ["yes ", "yep ", "yes "]:
                check word.isPositive() == true
            for word in ["yes \n", "yep \n", "yes \n", "yes    ", "yes \n \n"]: #make sure whitespace is correctly removed
                check word.isPositive() == true
            for word in ["yes \n q", "yes \n _", "yes_ "]: #make sure only whitespace is removed
                check word.isPositive() == false
            for word in ["no", "nope", "lel", "69", "", " "]: 
                check word.isPositive() == false
            
