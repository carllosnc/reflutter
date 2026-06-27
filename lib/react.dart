import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Reactive variable that can be shared across widgets.
///
/// A typed wrapper around [ValueNotifier]. The state and the actions that
/// mutate it live outside the widget tree, so widgets stay pure.
///
/// ```dart
/// var counter = globalState(0);
///
/// increment() => counter.setState((v) => v + 1);
/// ```
// ignore: camel_case_types
class globalState<T> extends ValueNotifier<T> {
  globalState(super.value);

  /// Registers [callback] to be invoked whenever the state changes.
  ///
  /// Returns a [VoidCallback] disposer: call it to remove the listener.
  ///
  /// **Must not be called while building a widget** (e.g. inside a `builder`,
  /// a page function executed during build, or [RenderGlobal]/[RenderLocal]
  /// builders). Doing so would register a brand new permanent listener on
  /// every rebuild and leak memory. Register effects either:
  /// - at top-level (runs once, lives forever — fine for globals), or
  /// - inside a [StatefulWidget]'s `initState`, or
  /// - via [RenderEffect], which binds the effect to a widget's lifetime.
  ///
  /// In debug builds a call during build triggers an [AssertionError].
  VoidCallback useEffect(VoidCallback callback) {
    assert(
      !_debugInBuild,
      'useEffect must not be called during build: it would leak a permanent '
      'listener on every rebuild. Register effects at top-level, in '
      'initState, or use RenderEffect.',
    );
    addListener(callback);
    return () => removeListener(callback);
  }

  /// Removes a previously registered [useEffect] callback.
  void removeEffect(VoidCallback callback) {
    removeListener(callback);
  }

  /// Updates the state using [callback] and notifies listeners exactly once.
  void setState(T Function(T value) callback) {
    super.value = callback(value);
  }
}

/// Reactive widget that rebuilds when a [ValueListenable] (typically a
/// [globalState]) changes.
///
/// The builder receives the current [value] — use it instead of re-reading
/// `state.value`, so the widget always renders the value that triggered the
/// rebuild and stays compatible with the `child` optimization.
class RenderGlobal<T> extends StatefulWidget {
  const RenderGlobal({
    super.key,
    required this.valueListenable,
    required this.builder,
  });

  final ValueListenable<T> valueListenable;
  final Widget Function(BuildContext context, T value, Widget? child) builder;

  @override
  State<RenderGlobal<T>> createState() => _RenderGlobalState<T>();
}

class _RenderGlobalState<T> extends State<RenderGlobal<T>> {
  late T _value;

  @override
  void initState() {
    super.initState();
    _value = widget.valueListenable.value;
    widget.valueListenable.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(covariant RenderGlobal<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.valueListenable != widget.valueListenable) {
      oldWidget.valueListenable.removeListener(_handleChange);
      _value = widget.valueListenable.value;
      widget.valueListenable.addListener(_handleChange);
    }
  }

  @override
  void dispose() {
    widget.valueListenable.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() {
    if (!mounted) return;
    setState(() => _value = widget.valueListenable.value);
  }

  @override
  Widget build(BuildContext context) {
    _debugInBuild = true;
    try {
      return widget.builder(context, _value, null);
    } finally {
      _debugInBuild = false;
    }
  }
}

/// Reactive widget that owns a [StateSetter], for state local to a single
/// widget (analogous to React's `useState` scoped to one component).
///
/// Note: unlike React's `useState`, the variables you close over are recreated
/// if the enclosing function is re-invoked by its parent. Keep the mutable
/// state *inside* the builder, or use [globalState] for anything that must
/// survive parent rebuilds.
class RenderLocal extends StatefulWidget {
  const RenderLocal({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, StateSetter setState) builder;

  @override
  State<RenderLocal> createState() => _RenderLocalState();
}

class _RenderLocalState extends State<RenderLocal> {
  @override
  Widget build(BuildContext context) {
    _debugInBuild = true;
    try {
      return widget.builder(context, setState);
    } finally {
      _debugInBuild = false;
    }
  }
}

/// Binds an [effect] to a [ValueListenable] for the lifetime of this widget.
///
/// This is the safe, lifecycle-aware equivalent of [globalState.useEffect] for
/// use inside the widget tree: the effect is registered in `initState` and
/// removed in `dispose`, so it never leaks across rebuilds.
///
/// ```dart
/// RenderEffect(
///   listenable: counter,
///   effect: () => print('counter: ${counter.value}'),
///   child: Scaffold(...),
/// )
/// ```
class RenderEffect<T> extends StatefulWidget {
  const RenderEffect({
    super.key,
    required this.listenable,
    required this.effect,
    required this.child,
  });

  final ValueListenable<T> listenable;
  final VoidCallback effect;
  final Widget child;

  @override
  State<RenderEffect<T>> createState() => _RenderEffectState<T>();
}

class _RenderEffectState<T> extends State<RenderEffect<T>> {
  @override
  void initState() {
    super.initState();
    widget.listenable.addListener(widget.effect);
  }

  @override
  void didUpdateWidget(covariant RenderEffect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listenable != widget.listenable ||
        oldWidget.effect != widget.effect) {
      oldWidget.listenable.removeListener(oldWidget.effect);
      widget.listenable.addListener(widget.effect);
    }
  }

  @override
  void dispose() {
    widget.listenable.removeListener(widget.effect);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ============================================================================
// Hooks
// ============================================================================
//
// A real hooks system (à la React) built on top of Flutter's `Element`/`State`.
// A [HookScope] owns a list of hook "slots" that survive rebuilds; hooks
// resolve to a slot by call order, exactly like React function components.
//
//   - [useState]   persistent local state that triggers rebuilds
//   - [useEffect]  side effects with a dependency array + cleanup
//   - [useMemo]    memoize a computed value
//   - [useRef]     a mutable container that persists across rebuilds
//
// Hooks MUST be called inside a [HookScope] builder. Calling them elsewhere
// throws an [AssertionError] (debug) / fails with a null scope (release).
// A hook called in a branch (`if`/`for`) breaks slot order — keep calls
// top-level in the builder, same rule as React.

/// Signature for [useEffect]'s callback. It may return a cleanup function
/// (or `null`) that runs before the next effect and on unmount.
typedef Effect = VoidCallback? Function();

/// Owns the hook slots for its subtree. Place it wherever you'd place a
/// function component in React.
///
/// ```dart
/// HookScope(
///   builder: (context) {
///     final count = useState(0);
///     useEffect(() {
///       print('count is ${count.value}');
///       return null;
///     }, [count.value]);
///     return FilledButton(
///       onPressed: () => count.set((v) => v + 1),
///       child: Text('${count.value}'),
///     );
///   },
/// )
/// ```
class HookScope extends StatefulWidget {
  const HookScope({super.key, required this.builder});

  final Widget Function(BuildContext context) builder;

  @override
  State<HookScope> createState() => _HookScopeState();
}

class _HookScopeState extends State<HookScope> {
  final List<_Hook> _hooks = [];
  int _hookIndex = 0;
  final List<_PendingEffect> _pending = [];

  @override
  void dispose() {
    for (final h in _hooks) {
      h.dispose();
    }
    _hooks.clear();
    _pending.clear();
    super.dispose();
  }

  void _scheduleRebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    _hookIndex = 0;
    final previousScope = _currentScope;
    _currentScope = this;
    try {
      return widget.builder(context);
    } finally {
      _currentScope = previousScope;
      _flushPending();
    }
  }

  void _flushPending() {
    if (_pending.isEmpty) return;
    final pending = List<_PendingEffect>.from(_pending);
    _pending.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final p in pending) {
        p.hook.cleanup?.call();
        p.hook.cleanup = p.effect();
      }
    });
  }
}

/// State holder returned by [useState].
class UseState<T> {
  UseState._(this._hook, this._scope);

  final _StateHook<T> _hook;
  final _HookScopeState _scope;

  T get value => _hook.value;

  set value(T v) {
    if (_hook.value == v) return;
    _hook.value = v;
    _scope._scheduleRebuild();
  }

  /// Updates the value via [f] and triggers a rebuild.
  void set(T Function(T value) f) => value = f(_hook.value);
}

/// A mutable container returned by [useRef]. Mutating [current] does NOT
/// trigger a rebuild.
class Ref<T> {
  Ref._(this._hook);
  final _RefHook<T> _hook;
  T get current => _hook.value;
  set current(T v) => _hook.value = v;
}

/// Persistent local state. The value survives rebuilds of the [HookScope]
/// (unlike a plain local variable) and setting it triggers a rebuild.
///
/// Equivalent to React's `useState`.
UseState<T> useState<T>(T initial) {
  final scope = _currentScope;
  assert(
    scope != null,
    'useState must be called inside a HookScope builder.',
  );
  scope!;
  final index = scope._hookIndex++;
  if (index >= scope._hooks.length) {
    scope._hooks.add(_StateHook<T>(initial));
  }
  final hook = scope._hooks[index] as _StateHook<T>;
  return UseState<T>._(hook, scope);
}

/// Runs [effect] after the frame, with dependency-driven re-runs.
///
/// - Omit [deps] → runs after every build.
/// - Pass an empty list → runs only on mount.
/// - Pass a list of values → re-runs when any value changes (compared with
///   `operator ==`).
///
/// The effect may return a cleanup function; it runs before the next effect
/// and when the [HookScope] unmounts. Equivalent to React's `useEffect`.
void useEffect(Effect effect, [List<Object?>? deps]) {
  final scope = _currentScope;
  assert(
    scope != null,
    'useEffect must be called inside a HookScope builder.',
  );
  scope!;
  final index = scope._hookIndex++;
  final _EffectHook hook;
  if (index >= scope._hooks.length) {
    hook = _EffectHook();
    scope._hooks.add(hook);
  } else {
    hook = scope._hooks[index] as _EffectHook;
  }

  final firstRun = !hook.mounted;
  hook.mounted = true;

  if (firstRun || _depsChanged(hook.deps, deps)) {
    hook.deps = deps;
    scope._pending.add(_PendingEffect(hook, effect));
  }
}

/// Memoizes [factory]'s result, recomputing only when [deps] change.
/// Equivalent to React's `useMemo`.
T useMemo<T>(T Function() factory, [List<Object?>? deps]) {
  final scope = _currentScope;
  assert(
    scope != null,
    'useMemo must be called inside a HookScope builder.',
  );
  scope!;
  final index = scope._hookIndex++;
  if (index >= scope._hooks.length) {
    final hook = _MemoHook<T>(factory(), deps);
    scope._hooks.add(hook);
    return hook.value;
  }
  final hook = scope._hooks[index] as _MemoHook<T>;
  if (_depsChanged(hook.deps, deps)) {
    hook.value = factory();
    hook.deps = deps;
  }
  return hook.value;
}

/// Returns a persistent mutable container. Mutating it does not rebuild.
/// Equivalent to React's `useRef`.
Ref<T> useRef<T>(T initial) {
  final scope = _currentScope;
  assert(
    scope != null,
    'useRef must be called inside a HookScope builder.',
  );
  scope!;
  final index = scope._hookIndex++;
  if (index >= scope._hooks.length) {
    scope._hooks.add(_RefHook<T>(initial));
  }
  final hook = scope._hooks[index] as _RefHook<T>;
  return Ref<T>._(hook);
}

bool _depsChanged(List<Object?>? old, List<Object?>? now) {
  if (now == null) return true; // no deps → run every time
  if (old == null) return true; // first dep run
  if (old.length != now.length) return true;
  for (var i = 0; i < old.length; i++) {
    if (old[i] != now[i]) return true;
  }
  return false;
}

// --- Internal hook slot types ---

abstract class _Hook {
  const _Hook();
  void dispose() {}
}

class _StateHook<T> extends _Hook {
  _StateHook(this.value);
  T value;
}

class _EffectHook extends _Hook {
  _EffectHook();
  List<Object?>? deps;
  VoidCallback? cleanup;
  bool mounted = false;

  @override
  void dispose() => cleanup?.call();
}

class _MemoHook<T> extends _Hook {
  _MemoHook(this.value, this.deps);
  T value;
  List<Object?>? deps;
}

class _RefHook<T> extends _Hook {
  _RefHook(this.value);
  T value;
}

class _PendingEffect {
  _PendingEffect(this.hook, this.effect);
  final _EffectHook hook;
  final Effect effect;
}

/// The currently active hook scope, set during a [HookScope] build.
_HookScopeState? _currentScope;

/// Tracks whether we are currently inside a `build` method, so [globalState.useEffect]
/// can refuse to register permanent listeners during build in debug mode.
bool _debugInBuild = false;
