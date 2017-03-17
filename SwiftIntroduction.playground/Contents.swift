/**
 iOS Workshop Playground.
 This playground aims to familiarize you with the basics of Swift and Cocoa Touch programming.
 */

/*
 The `Foundation` framework contiains tons of classes and functions that help you handle common data types and operations.
 For example, `Foundation` contains things like:
 - `Date`
 - `Cache`
 - `FileManager`
 - `InputStream`
 and many more!
 */
import Foundation

/*
 The `UIKit` framework, intuitively, loads UI elements, including things like.
 - `UITableView`
 - `UIButton`
 - `UINavigationController`
 and more.
 */
import UIKit

/***
 Let's start learning Swift!
 
 There are two types of declarations:
 - `let` declares a constant that cannot changed
 - `var` declares a variable that can be changed
 
 For example:
 */

let x = 2
//x has a value of 2
x + x

//Trying to change x causes a compile-time error. (Uncomment the below line to see the error.)
//x = 4

//We change change a var after we declare it!
var y = 3

y + x

y = 0

y + x

/***
 Types
 
 _Everything_ in Swift has a type! (It's a strongly typed language.) We can use function type(of:) to find the type of a variable.
 */

type(of: x)
type(of: y)

/*
 So we see that `x` and `y` are both `Int`s. Int.Type is returned because even types themselves have a type, which is usually their class.Type
 */

/*
 But how did Swift know that `x` and `y` were both `Int`s? We never told it!
 The answer is that Swift has inferred typing! Integer constants in Swift, unless we tell it otherwise, are assumed to be of type `Int`
 */
type(of: 123)

/* 
 So the reason that `x` is of type `Int` is because `2` was of type `Int` and we assigned it to `x`.
 Following this same pattern, if we assign `y` to some new `z`, `z` will inherit `y`'s type
 */

var z = y
type(of: z)

/*
 We can explicity declare types of variables by putting a `:` after the variable name and then a type. For example:
 */

var w : Int = -9

/*
 There are hundreds of other types just included in the Swift language, not to mention other frameworks.
 
 We'll go over a few of the important ones below.
 */

let a = 1 //We've already seen integers

let b = true //But we also have booleans

let c = 6.4 //And floating points! (The decimal constant is by default a double)
type(of: c)

let text = "Hello World!" //And strings!

/*
 Swift also has arrays! The type of an array is `[x]` where `x` is the type of element contained in the array.
 */

//This array is of type `[Int]`, because each element is of type `Int`
let nums = [1,2,3,4]

//We can initialize a new array by explicitly specifying the type in the declaration
var words : [String] = []
//Or we can explciity initialize the type. More on this later
words = [String]()

//Arrays have everything you would expect
words.append("The")
words.append("cake")
words.append("is")
words.append("a")
words.append("lie.")

//We can get the number of things in the array
words.count

//And access elements
words[0]
words[3]

//And change elements
words[4] = "pie."
words

//And remove them
words.remove(at: 3)
words

var sentence = ""
//We can iterate through elements, also append to strings with +
for word in words {
    sentence += word + " "
}

sentence

//We also have dictionaries, which are a mapping from keys to values
//This dictionary has an implicit type of [String : Int]
var collegeRankings = [
    "Berkeley": 10000,
    "Stanford": -9999
]

collegeRankings["UCLA"] = 0

collegeRankings["Berkeley"]

//We can iterate through dictionaries too!
var article = "College Rankings:\n"

for (key, value) in collegeRankings {
    article += "School: \(key) = \(value)\n" //We can also concat values into strings with this syntax
}

article

//We can print things to the console with the print() function
print(article)

//There are also tuple types, as we saw above in the for loop
let (speed, distance) = (59.7, 233)
speed
distance

let pair = (1,2)

//We can get elements of a tuple with .0, .1, etc
pair.0
pair.1

//pair[0] This doesn't work!

//We can also name the elements of our tuples
let luke = (name: "Luke", hoursOfSleep: 8, happiness: 0.9)

luke.name
luke.hoursOfSleep
luke.happiness

luke.0

/*
 Functions! We declare a function with `func`
 General function syntax looks like:
 
 func name(argumentName: ArgumentType, ...) -> ReturnType
 
 */

//This function adds two integers
func add(a: Int, b: Int) -> Int {
    return a + b
}

add(a: 8, b: 2)

//What is the type of add?
type(of: add)

//Functions are types that look like (ArgType, ArgType ...) -> ReturnType
//Using this, we can make higher order functions!

/*
 @escaping means that the function we give to doTwice should expect to be used after doTwice is called. This lets Swift know to keep around any variables used in f
 */

func doTwice(f: @escaping (Int)->Int) -> (Int)->Int {
    /*
     This is a closure! It's kind of like an inline function
     Closure syntax looks like:
     {(argumentName: ArgumentType ...)->ReturnType in
        return ...
     }
     */
    return {(num : Int)->Int in
        return f(f(num))
    }
}

/*
 Inferred typing lets us shorten closure syntax significantly
 Since we've defined the argument `f` to `doTwice` as `(Int)->Int` we know it takes one integer argument and returns an integer result.
 Using this we can write the argument
 */
let times4 = doTwice(f: {$0 * 2})

times4(3)

/*
 Swift can also be object oriented!
 Here's a class, Dog
 */

class Dog {
    
    //The `name` property of dog must be specified when dog is created, and cannot be changed after
    let name : String
    
    //Age must be specified when dog is created, but can be changed later
    var age : Int
    
    //Classes must have an initializer that sets up their variables
    init(name: String, age: Int) {
        self.name = name
        self.age = age
    }
    
    //classes can also have functions that do things
    func bark(times: Int) {
        //We can specify and iterate through ranges with lowerbound...upperbound (inclusive) or lowerbound..<upperbounds (exclusive)
        for i in 1...times {
            print("Bark \(i)")
        }
        print("My name is \(name). I am \(age) years old.")
    }
    
    //classes can also have `static` variables. These a property of the class rather than any instance
    static let paws = 4
    
}

let fido = Dog(name: "Fido", age: 4)

fido.bark(times: 3)

Dog.paws

//Protocols in Swift are like interfaces in Java. If a class adopts a protocol, it's required to implement those methods
protocol BabyAnimal {
    func grow()
}

//A class can inherit from a superclass (subclassing) and adopt multiple protocols
//The superclass (if there is one) must come first after the `:`
class Puppy : Dog, BabyAnimal {
    
    //Override, like Java indicates that we're overriding this method
    override func bark(times: Int) {
        for i in 0..<times {
            print("Yip \(i)")
        }
        
        super.bark(times: times)
    }
    
    //We must implement the grow function
    func grow() {
        age += 1
    }
    
}

let sam = Puppy(name: "same", age: 0)

sam.grow()

sam.age

//We can extend classes to add additional methods to them, but we can't add new properties
extension Dog {
    
    func increaseAgeByNameLength() {
        age += name.characters.count
    }
    
}

fido.increaseAgeByNameLength()

fido.age


