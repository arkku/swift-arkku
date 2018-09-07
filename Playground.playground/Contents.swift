import Foundation
import PlaygroundSupport
import CoreGraphics
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

var doublyLinkedList: NodeList = [ 1, 2, 3, 4 ]
doublyLinkedList.insertAsFirst(0)
for i in 5...10 { doublyLinkedList.append(i) }
doublyLinkedList.randomElement()
doublyLinkedList.removeAll { $0 % 2 == 0 }
doublyLinkedList
doublyLinkedList.replaceSubrange(doublyLinkedList.startIndex..<doublyLinkedList.endIndex, with: [ 1, 2, 3, 4 ])
doublyLinkedList.replaceSubrange(doublyLinkedList.startIndex..<doublyLinkedList.index(before: doublyLinkedList.endIndex), with: [ 11, 22, 33, 44 ])
doublyLinkedList.replaceSubrange(doublyLinkedList.index(after: doublyLinkedList.startIndex)..<doublyLinkedList.endIndex, with: [ 111, 222, 333, 444 ])
doublyLinkedList.replaceSubrange(doublyLinkedList.index(after: doublyLinkedList.startIndex)..<doublyLinkedList.index(before: doublyLinkedList.endIndex), with: [ 2, 33 ])
doublyLinkedList.count // O(1) count
doublyLinkedList.removeAll() // O(1) removeAll
doublyLinkedList.count
doublyLinkedList.append(1) // O(1) append
doublyLinkedList.reverse()
doublyLinkedList.append(0)
doublyLinkedList.reverse()
doublyLinkedList.insertAsFirst(0) // O(1) insert at any position
doublyLinkedList.reverse()
doublyLinkedList.reverse()
doublyLinkedList.insertAsFirst(1)
for element in doublyLinkedList.makeReverseIterator() {
    // By being careful, it is possible to modify the list during iteration
    doublyLinkedList.append(element)
}
for element in doublyLinkedList {
    doublyLinkedList.insertAsFirst(element)
}
print("\(doublyLinkedList)")

/*:
 ## Multipart Form Data

 Constructing multipart forms (e.g., for some HTTP APIs) manually is a pain.
 `FormData` simplifies this considerably.
*/

let fileURL = Bundle.main.url(forResource: "Hello", withExtension: "swift")!
let fileData = try! Data(contentsOf: fileURL)

//: A random boundary may be created that does not occur in some given data.
var formData = FormData(randomBoundaryFor: fileData)

//: The order of keys is preserved, as this is required for some forms.
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

let stream = ConcatenatedInputStream(of: [
    InputStream(data: formData.header),
    fileStream,
    InputStream(data: formData.footer)
    ])
stream.open()

/*:
 ## Read Data from an `InputStream`

 A simple extension of `InputStream` reads all data from the stream.
*/

let fileWrappedByForm = try! stream.readData()
print(String(data: fileWrappedByForm, encoding: .utf8)!)

/*:
 ## Multicast Delegates

 A container for holding multiple weak references to delegates.
*/

protocol SomeDelegate: class { func foo() }
class MyDelegate: SomeDelegate {
    init(_ name: String) { self.name = name }
    var name: String
    func foo() { print("\(name) delegate called") }
}

let delegates = MulticastDelegates<SomeDelegate>()
let permanentDelegate = MyDelegate("permanent")
var transientDelegate: SomeDelegate = MyDelegate("transient")
delegates.add(permanentDelegate)
delegates.add(transientDelegate)
delegates.add(permanentDelegate) // adding multiple times has no effect
delegates.perform { $0.foo() }
transientDelegate = MyDelegate("replacement")
delegates.perform { $0.foo() } // the "transient delegate" was probably removed
delegates.add(transientDelegate)
delegates.perform { $0.foo() }

class OtherClassDelegate: SomeDelegate {
    func foo() { print("other implementation called") }
}
delegates.removeAll()
transientDelegate = OtherClassDelegate()
delegates.add(transientDelegate) // can contain mixed classes
delegates.perform { $0.foo() }

/*:
 ## Dates and Times

 Some helpers for dealing with dates and times.
*/

let dateString = Date().iso8601String()
var date = Date(iso8601String: "1980-01-01T13:30:00+02:00")!
date = date.midnightBefore()
date += .days(246)
date.noonOfTheDay().ageInYears()
date = DateFormatter.iso8601Formatter.date(from: dateString)!

/*:
 ## Unicode Helpers

 Some helpers for dealing with Unicode strings and characters.
*/

"Yes! 👍🏻".containsEmoji == true
"Cats: 😻😻😻".containsOnlyEmoji == false
"👍🏻👾".containsOnlyEmoji == true
"No.".containsEmoji == false
let stringWithForeignPrefix = "عربى foo bar baz"
print(stringWithForeignPrefix)
print(stringWithForeignPrefix.forcedLeftToRight)

/*:
 ## Geometry Helpers
*/

var point = CGPoint(x: 2, y: 2)

//: New ways to create structs:
let windowRect = CGSize(square: 100).rectangle(at: .zero)
var uiRect1 = CGSize(square: 10).rectangle(at: point)

//: Helpers for moving and aligning rectangles:
uiRect1.move(centeredVerticallyInside: windowRect)
uiRect1.move(insideLeftEdgeOf: windowRect, margin: 10)

var uiRect2 = round(CGSize(width: uiRect1.width / 1.5, height: 20)).rectangle()
uiRect2.move(leftOf: uiRect1, margin: 10)
uiRect2.move(centeredVerticallyWith: uiRect1)
uiRect2.midY == uiRect1.midY

var uiRect3 = CGSize(square: 5).rectangle(centeredAt: uiRect2.center)
uiRect3.center == uiRect2.center

/*:
 ## Localization Helpers
*/

isRightToLeft // app's layout direction
print(stringWithForeignPrefix.forcedToNaturalDirection)

//: Date formatting according to the app's current language.
date.localizedString()
date.localizedShortString()
date.localizedShortTimeString()

//: Date formatting according to system preferences.
date.shortString()
date.shortTimeString()
date.mediumString()

//: Number formatting according to app's current language.
3.1415.localizedString(maxDecimals: 2)
10000000.localizedString()

//: Geometry helpers according to the layout direction.
var point2 = point
point.move(forward: 10)
if isRightToLeft { point2.move(left: 10) } else { point2.move(right: 10) }
point == point2

uiRect1.move(insideLeadingEdgeOf: windowRect)
uiRect2.move(after: uiRect1)

/*:
 ## Keychain Store

 The `KeychainStore` is a simple wrapper for storing `Codable` values
 in the keychain. The operations can be done asynchronously on another
 queue, but in this example the main queue is used to keep the playground
 flow simple.
 */

let keychain = KeychainStore(service: "com.github.arkku.swift-arkku", queue: .main)

keychain.store(fooBar, forKey: "FooBar", accessible: .alwaysThisDeviceOnly) { error in
    if let error = error {
        print("Keychain store failed: \(error)")
    } else {
        print("Keychain store success")
    }

    let updatedFooBar = FooBar(unwrapping: [ "foo":"updated".asValue, "bar":5.asValue ].asValue)!
    keychain.store(updatedFooBar, forKey: "FooBar", accessible: .alwaysThisDeviceOnly) { error in
        if let error = error {
            print("Keychain update failed: \(error)")
        } else {
            print("Keychain update success")
        }

        keychain.fetch(FooBar.self, forKey: "FooBar") { result in
            if let retrievedFooBar = result {
                print("Keychain fetch success: \(retrievedFooBar)")
            } else {
                print("Keychain fetch failed!")
            }

            keychain.removeValue(forKey: "FooBar") { error in
                if let error = error {
                    print("Keychain remove failed: \(error)")
                } else {
                    keychain.fetch(FooBar.self, forKey: "FooBar") { result in
                        print("Keychain remove \(result == nil ? "success" : "failed(?)")")
                    }
                }
            }
        }
    }
}
