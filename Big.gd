class_name Big
extends Reference

const max_int = 99999999
const very_big = "9999999999999999999999"
const max_length = 8

static func strip(string):
	while string[0] == "0" and string.length() > 1:
		string = string.substr(1)
	return string
	
# doesn't validate string... watch out!
static func get_array(string):
	string = strip(string)
	var result = []
	
	if string.length() <= max_length:
		result = [int(string)]
	else:
		var i = string.length() - max_length
		while i >= 0:
			result.push_front(int(string.substr(i, max_length)))
			i -= max_length
		result.push_front(int(string.substr(0, i + max_length)))
	
	# print("converted int " + string + " to array " + str(result))
	# print("")
	return result
		
static func get_string(array):
	var string = ""
	for element in array:
		string += str(element).pad_zeros(max_length)
	string = strip(string)
	return string
	
static func inc(string, maxi=very_big):
	var result = ""
	
	if less_or_equal(strip(maxi), strip(string)):
		result = "0"
		
	else:
		var array = get_array(string)
		
		var i = array.size() - 1
		while array[i] == max_int:
			array[i] = 0
			i -= 1
		
		if i < 0:
			array.push_front(1)
		else:
			array[i] += 1
	
		result = get_string(array)
	
	print("incrementing " + string)
	print("result: " + result)
	print("")
	return result

static func dec(string, maxi=very_big):
	var result = ""
	
	if less_or_equal(strip(string), "0"):
		result = maxi
	
	else:
		var array = get_array(string)
		
		var i = -1
		while array[i] == 0:
			array[i] = max_int
			i -= 1
			
		array[i] -= 1
		result = get_string(array)
	
	print("decrementing " + string)
	print("result: " + result)
	print("")
	return result

static func less_or_equal(a, b):
	print("evaluating if " + a + " <= " + b)
	a = get_array(a)
	b = get_array(b)
	
	var result = true
	
	if a.size() > b.size():
		result = false
	
	elif a.size() < b.size():
		result = true
	
	else:
		for i in range(0, a.size()):
			if a[i] > b[i]:
				result = false
				break
			elif a[i] < b[i]:
				result = true
				break
			
	print("result: " + str(result))
	print("")
	return result
	
static func rand(maxi):
	print("generating pseudo-random int out of maximum of " + maxi)
	var at_max = true
	var result = ""
		
	for i in range(0, maxi.length()):
		if at_max:
			result += str(randi() % (int(maxi[i]) + 1))
			if result[i] != maxi[i]:
				at_max = false
		else:
			result += str(randi() % 10)
	
	result = strip(result)
	print("result: " + result)
	print("")
	return result

static func bin(number):
	print("converting int to binary: " + number)
	var array = get_array(number)
	var result = ""

	while get_string(array) != "0":
		var carries = [0]
		for i in range(0, array.size()):
			carries.append(array[i] % 2)
			array[i] /= 2
		
		for i in range(0, carries.size()-1):
			array[i] += carries[i] * (max_int+1)/2
			
		result = str(carries[-1]) + result
	
	print("result: " + result)
	print("")
	return result
