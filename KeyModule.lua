return function()
    local scrambledPassword = "JUNK5202nosmirCJUNK"
    
    local unscrambled = string.sub(scrambledPassword, 5, -5)
    unscrambled = string.reverse(unscrambled)
    
    return unscrambled
end
