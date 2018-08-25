import Foundation
import PlaygroundSupport
import SwiftArkku

/*:
 ## Enum With Arbitrary Cases

 Sometimes there is a set of "known" cases, such as string keys in a
 dictionary, but also a need to support arbitrary unknown cases as well.
 The typical solution is to use `String` as they key type, but this loses
 the convenience and safety of an `enum`.

 The wrapper `KnownOrUnknownString` wraps an `enum` of the `known` cases,
 while providing the `unknown` case with arbitrary values.
*/

enum KnownFooKey: String, StringRepresentable {
    case foo, bar, baz
}
typealias FooKey = KnownOrUnknownString<KnownFooKey>

let someString: String = "baz"
let someKey = FooKey(someString) // determine from string whether known or not

/*:
 ### `KnownOrUnknownString` as key

 Dictionaries with `KnownOrUnknownString` keys can be accessed by the
 known key enum directly, as well as by string:
*/

var dict = [FooKey: String]([ .foo: "fooValue", .bar: "barValue" ])
dict[someKey] = "bazValue"
dict[.foo] == dict["foo"]       // direct access by known key
dict[someString] = "someValue"  // direct access by string

/*:
 ## A `Codable` "Any Type" Wrapper

 `AValue` is fully `Codable` and supports collections of mixed types.
 */

let thisDate = Date()
var mixedArray = [AValue](wrapping: [ 10, "foo", thisDate ])
mixedArray[wrapped: 0] == 10    // automatic unwrapping
mixedArray[0].integerValue != nil
mixedArray[1].integerValue == nil

/*:
 ### Wrapping and Unwrapping `AValue`

 Containers of `AValue` offer simple wrapping and unwrapping, whereas
 the `Valuable` protocol offers `asValue` for all types convertible to
 `AValue`. Meanwhile `Devaluable` offers `init?(unwrapping: AValue)`,
 which can also be accessed via `unwrapped()` of `AValue`.

 Together `Valuable` and `Devaluable` are `ValueCodable`.
*/

var valueDict = [FooKey: AValue](wrapping: dict)
valueDict[.foo]?.stringValue == "fooValue"

valueDict[wrapped: .bar] = 10       // automatic wrapping
valueDict[wrapped: .bar] == 10      // automatic unwrapping
valueDict[.bar] = 10.asValue        // manual wrapping
valueDict[.bar]?.unwrapped() == 10  // manual unwrapping
let someInt = Int(unwrapping: valueDict[.bar]!) // via init

//: Arbitrarily nested arrays and dictionaries are supported as `AValue`.

mixedArray.append(wrapped: valueDict)
mixedArray.last!.dictionaryValue!["foo"]?.stringValue == "fooValue"

/*:
 ## JSON Helpers

 JSON helpers include treating the encoded JSON as `String`, instead of `Data`.
*/

let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .millisecondsSince1970
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .millisecondsSince1970

let jsonString = try! encoder.encodedString(from: mixedArray)
let decodedArray = try! decoder.decode([AValue].self, from: jsonString)

/*:
 ## Encoding and Decoding `AValue`

 `AValue` dates are automatically reversible from JSON when
 encoded as `millisecondsSince1970`.
*/

let decodedDate = decodedArray[2].dateValue!
decodedDate.integerMillisecondsSince1970 == thisDate.integerMillisecondsSince1970

//: Nested structures can be unwrapped to more specific types:

let unwrappedDict = [KnownFooKey: AValue](unwrapping: decodedArray[3])!
unwrappedDict[.foo]!.stringValue == "fooValue"

/*:

 ### Implementing `Devaluable`

 Custom structures can also be made unwrappable from `AValue`:
*/

struct FooBar: Devaluable {
    let foo: String
    let bar: Int
    init?(unwrapping value: AValue) {
        guard   let dict = [KnownFooKey: AValue](unwrapping: value),
                let foo: String = dict[.foo]?.unwrapped(),
                let bar: Int = dict[.bar]?.unwrapped() else {
            return nil
        }
        self.foo = foo; self.bar = bar
    }
}

/*:
 Unwrappable structures can first be decoded into `AValue` and then
 later unwrapped into the structure. This can be very useful with
 nested, dynamic structures encoded as JSON, for example.
*/

let fooBar = FooBar(unwrapping: decodedArray[3])!
fooBar.foo == unwrappedDict[wrapped: .foo]!
fooBar.bar == unwrappedDict[wrapped: .bar]!

/*:
 ### Implementing `Codable` via `AValue`

 An `AValue` representation can also be used to implement `Codable` easily.
 Declaring conformance to `ValueEncodable` and/or `ValueDecodable` offers
 default implementations for `Encodable` and `Decodable`, respectively.
 Together these are `CodedAsValue`.
*/

extension FooBar: CodedAsValue {
    var asValue: AValue {
        return [KnownFooKey: AValue](wrapping: [ .foo: foo, .bar: bar ]).asValue
    }
}

let jsonFooBar = try! encoder.encodedString(from: fooBar)
let decodedFooBar = try! decoder.decode(FooBar.self, from: jsonFooBar)
decodedFooBar.foo == fooBar.foo && decodedFooBar.bar == fooBar.bar

/*:
 ## Forcing Dictionaries to Encode as Maps

 At the time of writing (when Swift 4.2 is the latest release), Swift
 inadvertently encodes enum-keyed dictionaries as arrays. This often means
 having to use plain string keys to prevent this.
*/

let incorrectJSON = try! encoder.encodedString(from: dict as [FooKey: String])

//: `MapCoded` offers a wrapper that enforces map encoding.

var map = dict.wrappedAsMapCoded
let correctJSON = try! encoder.encodedString(from: map)

/*:
 The `MapCoded` wrapper exposes all the most common functions of the wrapped
 dictionary.
*/

map[.foo] == map.dictionary[.foo]
map["foo"] = "foo"
map.removeValue(forKey: .bar)
map[.bar] = "bar"
map.updateValue("FOO", forKey: .foo)

var map2: MapCoded<KnownFooKey, String> = map.keyedByKnown()

//: `MapCoded` can also be combined with the `AValue` helpers.

var valueMap = valueDict.wrappedAsMapCoded
valueMap[wrapped: .bar] == 10
valueMap[.foo]!.stringValue! == valueMap["foo"]!.stringValue!

//: All of these wrappers are literal-convertible.

map2 = [ .foo: "foo", .baz: "baz" ]
let intValue: AValue = 10
let stringValue: AValue = "foo"
let dictValue: AValue = [ "int": intValue ]

/*:
 ## Linked List

 A simple linked list implementation is provided. It is a value type.
*/

var linkedList: LinkedList = [ 1, 1, 2, 3 ]
var otherList = linkedList

linkedList == otherList
linkedList.removeFirst() == 1
linkedList != otherList
linkedList > otherList
linkedList.insertAsFirst(0)
linkedList.first == 0
linkedList < otherList

for element in linkedList {
    print("\(element)")
}

/*:
 ## Node List

 The `DoubleLinkedList` is a reference type implementing a doubly-linked list.
 It allows O(1) removals and additions from any position. It also conforms to
 `MutableCollection`, `BidirectionalCollection`, and other such protocols.
*/

var doublyLinkedList: DoublyLinkedList = [ 1, 2, 3, 4 ]
var nextIteration = doublyLinkedList.tail
while let node = nextIteration {
    nextIteration = node.previous
    if node.data == 2 {
        doublyLinkedList.remove(node: node)
    }
}
doublyLinkedList.insertAsFirst(0)
for i in 5...10 { doublyLinkedList.append(i) }
doublyLinkedList.randomElement()
doublyLinkedList.removeAll { $0 % 2 == 0 }
doublyLinkedList

/*:
 ## Multipart Form Data

 Constructing multipart forms (e.g., for some HTTP APIs) manually is a pain.
 `FormData` simplifies this considerably.
*/

let fileURL = Bundle.main.url(forResource: "Hello", withExtension: "swift")!
let fileData = try! Data(contentsOf: fileURL)
var formData = FormData(randomBoundaryFor: fileData)

//: Keys and values may be appended in any order.
formData.append(value: "this is a form value", forKey: "someKey")
formData.append(value: "123".data(using: .utf8)!, forKey: "oneTwoThree")

//: The resulting form is available as `Data`.
formData.body

/*:
 A key may be appended without a value. This allows using the form's
 `header` and `footer` to "wrap" a file instead of duplicating the file's
 contents in memory just for the form.
*/

formData.append(keyOnly: "file", filename: "Hello.swift", contentType: "text/plain")

/*:
 ## Concatenated `InputStream`s

 Sometimes, such as with multipart forms containing large files, it may be
 handy to wrap have a single `InputStream` that actually reads from multiple
 other streams. `ConcatenatedInputStream` does exactly this.
*/

let fileStream = InputStream(url: fileURL)!

let stream = ConcatenatedInputStream(of: [InputStream(data: formData.header), fileStream, InputStream(data: formData.footer)])
stream.open()
let data = stream.readData()!

print(String(data: data, encoding: .utf8)!)
