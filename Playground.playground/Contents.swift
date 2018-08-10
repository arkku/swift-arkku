import Foundation
import SwiftArkku

// `KnownOrUnknownString` allows the convenience of enumerated "known" keys
// while still supporting storing and coding arbitrary strings.

enum KnownFooKey: String, StringRepresentable {
    case foo, bar, baz
}
typealias FooKey = KnownOrUnknownString<KnownFooKey>

let someString: String = "baz"
let someKey = FooKey(someString) // determine from string whether known or not

// Dictionaries with `KnownOrUnknownString` keys can be accessed by the
// known key enum directly, as well as by string:

var dict = [FooKey: String]([
    .foo: "fooValue", .bar: "barValue"
    ])
dict[someKey] = "bazValue"
dict[.foo] == dict["foo"]       // direct access by known key
dict[someString] = "someValue"  // direct access by string

// `AValue` is fully `Codable` and supports collections of mixed types:

let thisDate = Date()
var mixedArray = [AValue](wrapping: [ 10, "foo", thisDate ])
mixedArray[wrapped: 0] == 10    // automatic unwrapping
mixedArray[0].integerValue != nil
mixedArray[1].integerValue == nil

// Dates encoded as integers can transparently survive encoding:

mixedArray[2].integerValue == thisDate.integerMillisecondsSince1970
mixedArray[2] = thisDate.integerMillisecondsSince1970.asValue
mixedArray[2].dateValue!.integerMillisecondsSince1970 == thisDate.integerMillisecondsSince1970
mixedArray[2] = thisDate.asValue
thisDate.timeIntervalSince1970

// Containers of `AValue` offer convenient a interface:

var valueDict = [FooKey: AValue](wrapping: dict)
valueDict[.foo]?.stringValue == "fooValue"

valueDict[wrapped: .bar] = 10       // automatic wrapping
valueDict[wrapped: .bar] == 10      // automatic unwrapping
valueDict[.bar] = 10.asValue        // manual wrapping
valueDict[.bar]?.unwrapped() == 10  // manual unwrapping

// Arbitrarily nested arrays and dictionaries are supported as `AValue`:

mixedArray.append(wrapped: valueDict)
mixedArray.last!.dictionaryValue!["foo"]?.stringValue == "fooValue"

// JSON helpers include `encodedString` (instead of `Data`):

let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .millisecondsSince1970
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .millisecondsSince1970

let jsonString = try! encoder.encodedString(from: mixedArray)
let decodedArray = try! decoder.decode([AValue].self, from: jsonString)

// `AValue` dates are automatically reversible from JSON when
// encoded as `millisecondsSince1970`:

let decodedDate = decodedArray[2].dateValue!
decodedDate.integerMillisecondsSince1970 == thisDate.integerMillisecondsSince1970

// Nested structures can be unwrapped to more specific types:

let unwrappedDict = [KnownFooKey: AValue](unwrapping: decodedArray[3])!
unwrappedDict[.foo]!.stringValue == "fooValue"

// Custom structures can also be made unwrappable from `AValue`:

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

// Unwrappable structures can first be decoded into `AValue` and then
// later unwrapped into the structure. This can be very useful with
// nested, dynamic structures encoded as JSON, for example.

let fooBar = FooBar(unwrapping: decodedArray[3])!
fooBar.foo == unwrappedDict[wrapped: .foo]!
fooBar.bar == unwrappedDict[wrapped: .bar]!

// `AValue` representation can also be used to implement `Codable` easily:

extension FooBar: CodedAsValue, Codable {
    var asValue: AValue {
        return [KnownFooKey: AValue](wrapping: [ .foo: foo, .bar: bar ]).asValue
    }
}

let jsonFooBar = try! encoder.encodedString(from: fooBar)
let decodedFooBar = try! decoder.decode(FooBar.self, from: jsonFooBar)
decodedFooBar.foo == fooBar.foo && decodedFooBar.bar == fooBar.bar

// Swift inadvertently encodes enum-keyed dictionaries as arrays:

let incorrectJSON = try! encoder.encodedString(from: dict as [FooKey: String])

// This can be solved by wrapping in `MapCoded`

var map = dict.wrappedAsMapCoded
let correctJSON = try! encoder.encodedString(from: map)

// The `MapCoded` wrapper exposes the underlying dictionary in many ways:

map[.foo] == map.dictionary[.foo]
map["foo"] = "foo"
map.removeValue(forKey: .bar)
map[.bar] = "bar"
map.updateValue("FOO", forKey: .foo)

var map2: MapCoded<KnownFooKey, String> = map.keyedByKnown()

// `MapCoded` is can also be combined with the `AValue` helpers:

var valueMap = valueDict.wrappedAsMapCoded
valueMap[wrapped: .bar] == 10
valueMap[.foo]!.stringValue! == valueMap["foo"]!.stringValue!

// All of these wrappers are literal-convertible:

map2 = [ .foo: "foo", .baz: "baz" ]
let intValue: AValue = 10
let stringValue: AValue = "foo"
let dictValue: AValue = [ "int": intValue ]
