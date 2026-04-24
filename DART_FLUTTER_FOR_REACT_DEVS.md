# Dart & Flutter for React Devs — the Baby Edition

You know React. That's great news — most of Flutter's mental model maps cleanly onto React. This guide walks through the basics using React analogies.

---

## 1. The One Big Idea: **Widgets are Components**

In React, you build UIs from **Components**.
In Flutter, you build UIs from **Widgets**.

| React | Flutter |
|---|---|
| Component | Widget |
| `props` | constructor arguments |
| `state` | `State<T>` object |
| `useState` | `setState(() => ...)` |
| JSX | nested Dart constructors |
| `App.js` | `main.dart` |
| `package.json` | `pubspec.yaml` |
| `npm install` | `flutter pub get` |
| `npm run dev` | `flutter run` |
| Virtual DOM diffing | Widget tree diffing (same idea) |

Everything you see on screen is a Widget. Text? Widget. A button? Widget. Padding around that button? Also a widget. The whole app? Also a widget.

---

## 2. Dart — the Language

Dart is to Flutter what JavaScript (or TypeScript) is to React. It's statically typed, class-based, and has `async`/`await` just like JS.

### Variables

```dart
var name = 'Sushi';        // like `let` in JS, type inferred
String name = 'Sushi';     // explicitly typed
final age = 30;            // like `const` in JS — can't reassign
const pi = 3.14;           // compile-time constant (stronger than final)
```

- `var` → JS `let`
- `final` → JS `const` (runtime)
- `const` → compile-time constant. Flutter uses this a LOT for performance.

### Null safety

Dart makes you say whether a value can be null.

```dart
String name = 'Sushi';     // can NEVER be null
String? name = null;       // the `?` means "might be null"
```

If you have `String?` and want to use it, you must check:
```dart
if (name != null) { print(name.length); }
// or use the "bang" operator when you're SURE:
print(name!.length);  // crashes if null
```

Think TypeScript strict null checks.

### Functions

```dart
int add(int a, int b) {
  return a + b;
}

// Arrow function (single expression)
int add(int a, int b) => a + b;
```

### Named parameters (super important in Flutter!)

In React you pass props like `<Button color="red" size="large" />`.
In Dart, functions/constructors do the same with **named parameters**:

```dart
void greet({String? name, int age = 0}) { ... }

greet(name: 'Sushi', age: 30);   // looks like props!
```

You'll see this constantly in widget constructors:
```dart
Text('Hello', style: TextStyle(fontSize: 20))
Padding(padding: EdgeInsets.all(8), child: ...)
```

### Classes (briefly)

```dart
class Dog {
  final String name;
  Dog(this.name);            // shorthand constructor

  void bark() => print('$name says woof');
}

final d = Dog('Rex');
d.bark();
```

String interpolation: `'$name'` or `'${name.toUpperCase()}'` — like JS backticks.

---

## 3. Hello World in Flutter

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());    // like ReactDOM.render(...)
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Hello!')),
      ),
    );
  }
}
```

Compare to a React functional component:
```jsx
function MyApp() {
  return <div><h1>Hello!</h1></div>;
}
```

Same shape! `build()` is just a fancy `return JSX`. There is no JSX in Dart — you nest constructors instead. Yes it gets indented. You get used to it.

---

## 4. StatelessWidget vs StatefulWidget

This is the big one.

### StatelessWidget = functional component with no state

```dart
class Greeting extends StatelessWidget {
  final String name;
  const Greeting({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Text('Hello $name');
  }
}
```

React equivalent:
```jsx
function Greeting({ name }) {
  return <p>Hello {name}</p>;
}
```

### StatefulWidget = component with `useState`

StatefulWidgets are weirdly split into **two classes**. Don't panic — it's the same concept as React, just more typing.

```dart
class Counter extends StatefulWidget {
  const Counter({super.key});

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int count = 0;    // this is your state

  void increment() {
    setState(() {   // like React's setState — triggers a rebuild
      count++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Count: $count'),
        ElevatedButton(onPressed: increment, child: const Text('+')),
      ],
    );
  }
}
```

React equivalent:
```jsx
function Counter() {
  const [count, setCount] = useState(0);
  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={() => setCount(count + 1)}>+</button>
    </div>
  );
}
```

**Why two classes?** The `Counter` widget is immutable (rebuilt constantly), but `_CounterState` survives across rebuilds — that's where your mutable data lives. The leading `_` means "private to this file" (like a non-exported symbol).

### Lifecycle methods (like `useEffect`)

Inside a `State` class:
- `initState()` — runs once when widget is created → `useEffect(() => {...}, [])`
- `dispose()` — cleanup → the return function of `useEffect`
- `didUpdateWidget()` — props changed → `useEffect` with deps

```dart
@override
void initState() {
  super.initState();
  // fetch data, subscribe to streams, etc.
}

@override
void dispose() {
  // cancel subscriptions, controllers, etc.
  super.dispose();
}
```

---

## 5. Building UI — No JSX, just nesting

Instead of JSX children, widgets take a `child` (singular) or `children` (list):

```dart
Column(
  children: [
    Text('Line 1'),
    Text('Line 2'),
    Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: () => print('tapped'),
        child: const Text('Tap me'),
      ),
    ),
  ],
)
```

Common layout widgets (learn these 5 and you can build most UIs):
- `Column` — vertical stack (like flexbox `flex-direction: column`)
- `Row` — horizontal stack
- `Container` — div with padding/margin/decoration
- `Padding` — just padding
- `Center` — centers its child

And content widgets:
- `Text` — text
- `Image.network(url)` / `Image.asset(path)` — images
- `ElevatedButton`, `TextButton`, `IconButton` — buttons
- `TextField` — input

---

## 6. Async: `Future` and `Stream`

| React/JS | Dart |
|---|---|
| `Promise<T>` | `Future<T>` |
| `async / await` | `async / await` (identical!) |
| Event stream / Observable | `Stream<T>` |

```dart
Future<String> fetchUser() async {
  final res = await http.get(Uri.parse('...'));
  return res.body;
}
```

### Showing async data in UI: `FutureBuilder` / `StreamBuilder`

Flutter has no hooks by default, so for async UI you use a widget that handles loading/error/data states for you:

```dart
FutureBuilder<String>(
  future: fetchUser(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator();
    }
    if (snapshot.hasError) return Text('Error: ${snapshot.error}');
    return Text('Hello ${snapshot.data}');
  },
)
```

Like a React Suspense boundary + data fetching hook mashed together.

---

## 7. `pubspec.yaml` — your `package.json`

```yaml
name: sushi_social
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.0.0
```

- Add a package: edit `pubspec.yaml`, then run `flutter pub get`.
- Find packages at [pub.dev](https://pub.dev) (Dart's npm).

---

## 8. State management — the bigger picture

`setState` is fine for local component state (like `useState`). For app-wide state (like Redux / Zustand / Context):
- **Provider** — simplest, officially recommended
- **Riverpod** — Provider's cooler sibling
- **Bloc** — if you like Redux-style events/reducers
- **GetX** — opinionated all-in-one

For a small app, start with `setState` + `Provider`. Don't over-engineer.

---

## 9. Quick glossary

- **BuildContext** — a handle to your widget's position in the tree. You pass it around to look up themes, navigate, show dialogs, etc. Think "the React tree but you can query it."
- **key** — like React `key`, but also used to preserve state across rebuilds.
- **Material** / **Cupertino** — two design systems. Material = Google/Android look. Cupertino = iOS look. Most apps use Material.
- **Scaffold** — a widget that gives you the basic page structure (app bar, body, floating button). Use it as the root of most screens.
- **`const` constructors** — when you see `const Text('hi')`, that widget is created once and reused forever. Performance win. Use `const` wherever your linter suggests it.

---

## 10. Best practices — the short list

1. **Use `const` constructors everywhere possible.** The linter will yell at you; listen to it. Free performance.
2. **Break big `build` methods into smaller widgets.** Same reason you split big React components — readability and rebuild scope.
3. **Prefer `StatelessWidget` unless you actually need state.** Same as preferring pure functional components.
4. **Always `dispose()` controllers and subscriptions** (TextEditingController, StreamSubscription, etc.). Memory leak city otherwise.
5. **Don't do heavy work in `build()`.** It runs often. Move expensive stuff to `initState` or memoize it.
6. **Use named parameters + `required`** for anything non-trivial. Makes call sites self-documenting.
7. **Run `flutter analyze`** often — it's your ESLint + TS checker combined.
8. **Hot reload is your friend** — press `r` in the terminal running `flutter run` and your UI updates in milliseconds without losing state. Magic.

---

## 11. Where to go next in this repo

You've got a Flutter app in `lib/`:
- `lib/main.dart` — app entry point (`runApp(...)`)
- `lib/pages/auth_page.dart`, `home_page.dart`, `session_page.dart` — screens

Open `main.dart` first. You'll see a `class MyApp extends StatelessWidget` — now you know what that means. Then follow where it routes to. Ask me to walk through any file when you're ready.
