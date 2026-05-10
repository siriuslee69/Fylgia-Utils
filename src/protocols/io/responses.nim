import strutils

proc isPositive*(str: string): bool =
    ## Returns true for positive sounding strings, false otherwise.
    let 
        conv_str: string = str.strip().toLowerAscii()
    if(conv_str == "yes" or 
        conv_str == "y" or
        conv_str == "+" or
        conv_str == "ja" or
        conv_str == "oui" or
        conv_str == "yarp" or
        conv_str == "ye" or
        conv_str == "yep"):
        return true
    else: 
        return false


when defined(test):
    
    import std/unittest, ../debugging/checks

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
            
