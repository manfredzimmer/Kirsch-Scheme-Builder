# Performance Improvement Plan

After importing 911 field options, the UI becomes sluggish due to several bottlenecks in the single-file Vue 3 app. Below are the identified issues and concrete solutions.

## 1. `getTranslationText()` linear scan per option (HIGH IMPACT)

**Problem:** `getTranslationText()` (line 2345) calls `getTranslation()` which does `translations.value.find(t => t.id === id)` — an O(n) scan through the **entire translations array** for **each option** on **every re-render**. With 911 options × N translations, this dominates render time.

**Solution:** Replace `Array.find` with a `Map` for O(1) lookups:

```js
// Add a computed map once
const translationMap = computed(() => {
    const map = new Map();
    for (const t of translations.value) {
        map.set(t.id, t);
    }
    return map;
});

function getTranslation(id) {
    return translationMap.value.get(id) || null;
}
```

The Map is rebuilt only when `translations.value` changes, not on every function call.

## 2. `getFieldOptionsList()` called in `v-for` (HIGH IMPACT)

**Problem:** `getFieldOptionsList(field.id)` (line 2364) is called **as a function in the template** (`v-for="opt in getFieldOptionsList(field.id)"`). Functions in templates execute on **every re-render**, filtering and sorting all 911 options each time.

**Solution:** Replace with a computed property that groups options by `fieldId`:

```js
const optionsByField = computed(() => {
    const map = {};
    for (const opt of fieldOptions.value) {
        if (!map[opt.fieldId]) map[opt.fieldId] = [];
        map[opt.fieldId].push(opt);
    }
    // Sort each group once
    for (const key of Object.keys(map)) {
        map[key].sort((a, b) => a.order - b.order);
    }
    return map;
});

// In template: v-for="opt in optionsByField[field.id] || []"
```

This sorts and groups only when `fieldOptions.value` actually changes, not on every render.

## 3. `onUpdated` → `reinitSortable()` on every change (MEDIUM IMPACT)

**Problem:** `onUpdated` (line 4062) calls `reinitSortable()` on **every** Vue DOM update, even for unrelated state (typing in a text field, hovering, etc.). SortableJS re-scans all DOM nodes in the option container (911 items) each time.

**Solution A — Conditional reinit:** Only reinit when the relevant arrays actually changed:

```js
let prevOptionsLength = 0;
onUpdated(() => {
    if (fieldOptions.value.length !== prevOptionsLength) {
        prevOptionsLength = fieldOptions.value.length;
        reinitSortable();
    }
});
```

**Solution B — Manual trigger:** Remove `onUpdated` and call `reinitSortable()` explicitly after mutations that affect DOM structure (add/remove/order categories, fields, options).

## 4. Template function calls create new objects per render (MEDIUM IMPACT)

**Problem:** `getFieldOptionsList()` returns a new sorted array reference on every call, which prevents Vue from applying its `v-for` patch optimization. In Vue 3, stable references help the diff algorithm skip unchanged items.

**Solution:** Combine with solution #2 — a stable computed map returns the **same array reference** as long as `fieldOptions.value` hasn't changed.

## 5. `v-memo` on option items (MEDIUM IMPACT)

**Problem:** Even when unrelated state changes, Vue re-renders all 911 option divs because nothing tells it they can be skipped.

**Solution:** Add `v-memo` to skip re-rendering unchanged option items:

```html
<div v-for="opt in optionsByField[field.id] || []" :key="opt.id"
     v-memo="[opt.value, opt.labelTranslationId, opt.order]"
     ...>
```

This tells Vue: only re-render this `<div>` if `opt.value`, `opt.labelTranslationId`, or `opt.order` actually changed.

## 6. `initOptionSortable()` with 911 items (LOW IMPACT)

**Problem:** SortableJS sorts by dragging, which is nearly useless with 911 items. The Sortable instance still scans all 911 DOM nodes on init.

**Solution:** Only init Sortable on the option container if the number of options is below a threshold (e.g. 50). For larger option sets, skip Sortable initialization on options or use a lighter drag handle.

```js
function initOptionSortable() {
    const container = document.querySelector('.option-sortable-container');
    if (!container || container.children.length > 50) return;
    // ... existing Sortable init
}
```

## 7. Virtual scrolling (LOW IMPACT / COMPLEX)

**Problem:** Rendering 911 DOM nodes at once is inherently slow.

**Solution:** For very large option lists (>500), consider virtual scrolling (e.g. `vue-virtual-scroller`). However, this adds a dependency and complexity. The solutions above should provide enough improvement for 911 items without this.

## Expected Improvement

| Issue | Est. Improvement |
|-------|-----------------|
| #1 + #2 (Map + computed grouping) | 10-50x faster render |
| #3 (conditional reinit) | Eliminates re-render storms |
| #4 + #5 (stable refs + v-memo) | Skips 99% of patch work |
| #6 (skip Sortable for large lists) | Smoother initial render |

After applying #1-#6, the UI should feel responsive even with 1000+ options.
