# Create an array
$list = @("Item1", "Item2", "Item3")

# Add an item to the array
$list += "Item4"

# Display the list
$list

########################################

# Create an ArrayList
$list = [System.Collections.ArrayList]@("Item1", "Item2", "Item3")

# Add an item to the ArrayList
$list.Add("Item4")

# Display the list
$list

#######################################

# Create a Generic List
$list = [System.Collections.Generic.List[string]]::new()
$list.Add("Item1")
$list.Add("Item2")
$list.Add("Item3")

# Add an item to the Generic List
$list.Add("Item4")

# Display the list
$list

#######################################

# Create a HashTable
$list = @{}
$list["Key1"] = "Value1"
$list["Key2"] = "Value2"

# Add an item to the HashTable
$list["Key3"] = "Value3"

# Display the list
$list

#######################################

# Create an array to store VM names
$vmNames = @()

# Add VM names to the array
$vmNames += "VM1"
$vmNames += "VM2"
$vmNames += "VM3"

# Display the VM names
$vmNames
