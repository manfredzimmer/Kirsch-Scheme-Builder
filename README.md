# Kirsch-Categories

Kirsch-Categories is a browser-based admin tool for creating category trees and dynamic listing fields with localization. It is designed for teams that need to define structured category data, field definitions, select options, field visibility rules, and translated labels without editing JSON by hand.

The app is currently a single-file static application in `index.html`. It runs directly in the browser and exports the created project as a ZIP file containing JSON files.

## Features

- Category tree editor with parent-child categories, ordering, levels, and optional metadata.
- Dynamic fields per category.
- Supported field types: `text`, `textarea`, `number`, `select`, `boolean`, `date`, and `datetime`.
- Field configuration per type, for example min/max values, text length limits, patterns, textarea rows, units, multi-select, date/time patterns, and visibility toggles for date segments.
- Required/optional field handling.
- Localized field labels, placeholders, category names, and option labels.
- Language management with missing-translation warnings.
- Select field options with localized labels, stable slug values, and manual or alphabetical sorting.
- Field dependencies: show one field only after another field in the same category has a value.
- Boolean field control: boolean fields can control visibility of other fields via true/false conditions.
- Option filters: restrict options in one select field based on a selected option in another select field.
- Field option dependencies: show a field when specific select options are chosen (configurable via searchable multi-select modal).
- Drag-and-drop sorting for categories, fields, and options.
- Editable project name with inline rename.
- Field copy workflows:
  - Reference copy, where one field definition is reused in another category.
  - Deep copy, where a new field is created with copied options.
- Delete preview with global and local delete actions for categories and referenced fields.
- Import/export as a portable ZIP archive.

## Running Locally

No build step is required.

1. Open `index.html` in a browser.
2. Create or import a project.
3. Export the result as a ZIP file.

The application depends on CDN-hosted browser libraries:

- Vue 3
- Tailwind CSS
- Font Awesome
- JSZip
- SortableJS

## Exported ZIP Structure

Exporting a project creates a ZIP file with these JSON files:

```text
project.json
categories.json
fields.json
fieldCategories.json
fieldOptions.json
fieldDependencies.json
optionDependencies.json
fieldOptionDependencies.json
translations.json
```

## JSON Files

### project.json

Stores the project name.

```json
{
  "name": "My Project"
}
```

### categories.json

Stores the category tree.

```json
[
  {
    "id": 1,
    "translationId": 1,
    "parentId": null,
    "level": 0,
    "order": 0,
    "metadata": {
      "icon": "car"
    }
  },
  {
    "id": 2,
    "translationId": 2,
    "parentId": 1,
    "level": 1,
    "order": 0,
    "metadata": null
  }
]
```

Fields:

- `id`: Numeric category id.
- `translationId`: Id in `translations.json`.
- `parentId`: Parent category id, or `null` for root categories.
- `level`: Computed nesting level.
- `order`: Sort order within the same parent.
- `metadata`: Optional key-value metadata object.

### fields.json

Stores reusable field definitions.

```json
[
  {
    "id": 1,
    "translationId": 10,
    "type": "select",
    "placeholderTranslationId": 11,
    "required": true,
    "config": {
      "multiple": false
    }
  },
  {
    "id": 2,
    "translationId": 12,
    "type": "number",
    "placeholderTranslationId": 13,
    "required": false,
    "config": {
      "min": 0,
      "max": 100000,
      "step": 1,
      "unit": "km"
    }
  }
]
```

Fields:

- `id`: Numeric field id.
- `translationId`: Label translation id.
- `type`: One of `text`, `textarea`, `number`, `select`, `boolean`, `date`, or `datetime`.
- `placeholderTranslationId`: Placeholder translation id, or `null`.
- `required`: Whether the field is required.
- `config`: Type-specific configuration object.

  **`date` config:**
  - `allowFuture` (boolean): Allow future dates.
  - `minDateText` (string): Pattern-based minimum date constraint. Supports: `today`, `-d N`, `-m N`, `-y N`, `+d N`, `+m N`, `+y N`. Patterns can be combined (e.g. `-y 100, -d30`).
  - `maxDateText` (string): Same pattern logic for maximum date.
  - `showDay` (boolean): Show day picker.
  - `showMonth` (boolean): Show month picker.
  - `showYear` (boolean): Show year picker.

  **`datetime` config:**
  - Same as `date` plus:
  - `minDateTimeText` (string): Same as `minDateText` with additional patterns `-hh N`, `-mm N`, `-ss N`, `+hh N`, `+mm N`, `+ss N`.
  - `maxDateTimeText` (string): Same pattern logic for maximum date-time.
  - `showHour` (boolean): Show hour picker.
  - `showMinute` (boolean): Show minute picker.
  - `showSecond` (boolean): Show second picker.

### fieldCategories.json

Links fields to categories and stores field ordering per category.

```json
[
  {
    "id": 1,
    "fieldId": 1,
    "categoryId": 2,
    "order": 0
  },
  {
    "id": 2,
    "fieldId": 2,
    "categoryId": 2,
    "order": 1
  }
]
```

Fields:

- `id`: Numeric link id.
- `fieldId`: Field id from `fields.json`.
- `categoryId`: Category id from `categories.json`.
- `order`: Field order inside that category.

The same `fieldId` can appear in multiple categories when a field is copied by reference.

### fieldOptions.json

Stores select options for fields with `type: "select"`.

```json
[
  {
    "id": 1,
    "fieldId": 1,
    "labelTranslationId": 20,
    "value": "bmw",
    "order": 0
  },
  {
    "id": 2,
    "fieldId": 1,
    "labelTranslationId": 21,
    "value": "audi",
    "order": 1
  }
]
```

Fields:

- `id`: Numeric option id.
- `fieldId`: Select field id.
- `labelTranslationId`: Option label translation id.
- `value`: Stable slug value used by the consuming app.
- `order`: Option order inside the field.

### fieldDependencies.json

Stores field visibility dependencies.

```json
[
  {
    "id": 1,
    "fieldId": 2,
    "dependsOnFieldId": 1
  }
]
```

Fields:

- `id`: Numeric dependency id.
- `fieldId`: Dependent field id. This field is hidden until the dependency is fulfilled.
- `dependsOnFieldId`: Source field id. When this field has a value, `fieldId` can be shown.

Example: `Model` depends on `Brand`. The `Model` field is hidden until `Brand` has a selected value.

### optionDependencies.json

Stores option filtering rules for select fields.

```json
[
  {
    "id": 1,
    "optionId": 1,
    "visibleOptionId": 10
  },
  {
    "id": 2,
    "optionId": 1,
    "visibleOptionId": 11
  }
]
```

Fields:

- `id`: Numeric option dependency id.
- `optionId`: Trigger option id. When this option is selected, the filter applies.
- `visibleOptionId`: Option id that should remain visible.

Example: If `Brand = BMW`, only BMW models are visible in the `Model` select field.

### fieldOptionDependencies.json

Stores field visibility rules triggered by specific select options.

```json
[
  {
    "id": 1,
    "fieldId": 5,
    "optionId": 20
  },
  {
    "id": 2,
    "fieldId": 5,
    "optionId": 21
  }
]
```

Fields:

- `id`: Numeric dependency id.
- `fieldId`: Dependent field id. This field is hidden until one of its configured options is selected.
- `optionId`: An option id from a select field in the same category. When this option is selected, `fieldId` is shown.

A field can have multiple entries (OR logic). When combined with a `fieldDependencies` entry, both conditions must be met (AND logic).

### translations.json

Stores localized text for categories, fields, placeholders, and option labels.

```json
[
  {
    "id": 1,
    "translation": {
      "de": "Fahrzeuge",
      "en": "Vehicles"
    }
  },
  {
    "id": 10,
    "translation": {
      "de": "Marke",
      "en": "Brand"
    }
  }
]
```

Fields:

- `id`: Numeric translation id.
- `translation`: Object keyed by language code.

Consumers should fall back to a default language when a requested localization is missing.

## TypeScript Usage Example

The following example shows how an application can use the exported JSON data to render localized fields, handle select changes, reveal dependent fields, and filter options based on selected options.

```tsx
type Locale = "de" | "en" | string;

type Category = {
  id: number;
  translationId: number;
  parentId: number | null;
  level: number;
  order: number;
  metadata?: Record<string, unknown> | null;
};

type FieldType = "text" | "textarea" | "number" | "select" | "boolean" | "date" | "datetime";

type Field = {
  id: number;
  translationId: number;
  type: FieldType;
  placeholderTranslationId?: number | null;
  required: boolean;
  config?: Record<string, unknown> | null;
};

type FieldCategory = {
  id: number;
  fieldId: number;
  categoryId: number;
  order: number;
};

type FieldOption = {
  id: number;
  fieldId: number;
  labelTranslationId: number;
  value: string;
  order: number;
};

type FieldDependency = {
  id: number;
  fieldId: number;
  dependsOnFieldId: number;
  includeWhen?: boolean;
};

type OptionDependency = {
  id: number;
  optionId: number;
  visibleOptionId: number;
};

type FieldOptionDependency = {
  id: number;
  fieldId: number;
  optionId: number;
};

type Translation = {
  id: number;
  translation: Record<string, string>;
};

type ExportedData = {
  categories: Category[];
  fields: Field[];
  fieldCategories: FieldCategory[];
  fieldOptions: FieldOption[];
  fieldDependencies: FieldDependency[];
  optionDependencies: OptionDependency[];
  fieldOptionDependencies: FieldOptionDependency[];
  translations: Translation[];
};

type FormValues = Record<number, string | number | string[] | undefined>;

function t(translations: Translation[], id: number | null | undefined, locale: Locale, fallback: Locale = "en") {
  if (!id) return "";
  const entry = translations.find((item) => item.id === id);
  return entry?.translation[locale] || entry?.translation[fallback] || entry?.translation.de || "";
}

function getFieldsForCategory(data: ExportedData, categoryId: number) {
  const orderedLinks = data.fieldCategories
    .filter((link) => link.categoryId === categoryId)
    .sort((a, b) => a.order - b.order);

  return orderedLinks
    .map((link) => data.fields.find((field) => field.id === link.fieldId))
    .filter((field): field is Field => Boolean(field));
}

function hasValue(value: FormValues[number]) {
  return Array.isArray(value) ? value.length > 0 : value !== undefined && value !== "";
}

function isFieldVisible(field: Field, values: FormValues, dependencies: FieldDependency[], optionDeps: FieldOptionDependency[]) {
  let fieldDepMet = true;
  const dependency = dependencies.find((dep) => dep.fieldId === field.id);
  if (dependency) {
    const sourceValue = values[dependency.dependsOnFieldId];
    if (dependency.includeWhen !== undefined) {
      fieldDepMet = sourceValue === dependency.includeWhen;
    } else {
      fieldDepMet = hasValue(sourceValue);
    }
  }

  let optionDepMet = true;
  const fieldOptionDeps = optionDeps.filter((d) => d.fieldId === field.id);
  if (fieldOptionDeps.length > 0) {
    const selectedOptionIds = getSelectedOptionIds(values);
    optionDepMet = fieldOptionDeps.some((d) => selectedOptionIds.has(d.optionId));
  }

  return fieldDepMet && optionDepMet;
}

function getSelectedOptionIds(values: FormValues) {
  const ids = new Set<number>();

  for (const value of Object.values(values)) {
    if (Array.isArray(value)) {
      value.forEach((item) => ids.add(Number(item)));
    } else if (value !== undefined && value !== "") {
      ids.add(Number(value));
    }
  }

  return ids;
}

function getOptionsForField(data: ExportedData, fieldId: number, values: FormValues) {
  const options = data.fieldOptions
    .filter((option) => option.fieldId === fieldId)
    .sort((a, b) => a.order - b.order);

  const selectedOptionIds = getSelectedOptionIds(values);
  const activeFilters = data.optionDependencies.filter((dep) => selectedOptionIds.has(dep.optionId));

  const filtersForThisField = activeFilters.filter((dep) =>
    options.some((option) => option.id === dep.visibleOptionId)
  );

  if (filtersForThisField.length === 0) return options;

  const visibleOptionIds = new Set(filtersForThisField.map((dep) => dep.visibleOptionId));
  return options.filter((option) => visibleOptionIds.has(option.id));
}

function CategoryForm(props: {
  data: ExportedData;
  categoryId: number;
  locale: Locale;
  values: FormValues;
  onValuesChange: (values: FormValues) => void;
}) {
  const { data, categoryId, locale, values, onValuesChange } = props;

  const fields = getFieldsForCategory(data, categoryId).filter((field) =>
    isFieldVisible(field, values, data.fieldDependencies, data.fieldOptionDependencies)
  );

  function onSelectedChange(fieldId: number, optionId: string) {
    onValuesChange({
      ...values,
      [fieldId]: optionId
    });
  }

  return (
    <form>
      {fields.map((field) => {
        const label = t(data.translations, field.translationId, locale);
        const placeholder = t(data.translations, field.placeholderTranslationId, locale);

        if (field.type === "select") {
          const options = getOptionsForField(data, field.id, values);

          return (
            <label key={field.id}>
              {label}
              <select
                required={field.required}
                value={String(values[field.id] ?? "")}
                onChange={(event) => onSelectedChange(field.id, event.target.value)}
              >
                <option value="">{placeholder || label}</option>
                {options.map((option) => (
                  <option key={option.id} value={option.id}>
                    {t(data.translations, option.labelTranslationId, locale)}
                  </option>
                ))}
              </select>
            </label>
          );
        }

        if (field.type === "textarea") {
          return (
            <label key={field.id}>
              {label}
              <textarea
                required={field.required}
                placeholder={placeholder}
                value={String(values[field.id] ?? "")}
                onChange={(event) =>
                  onValuesChange({ ...values, [field.id]: event.target.value })
                }
              />
            </label>
          );
        }

        return (
          <label key={field.id}>
            {label}
            <input
              type={field.type === "number" ? "number" : "text"}
              required={field.required}
              placeholder={placeholder}
              value={String(values[field.id] ?? "")}
              onChange={(event) =>
                onValuesChange({ ...values, [field.id]: event.target.value })
              }
            />
          </label>
        );
      })}
    </form>
  );
}
```

In this example:

- The selected category determines which fields are rendered.
- `translations.json` provides the label and placeholder text for the requested locale.
- `fieldDependencies.json` controls whether a field is visible (including boolean true/false conditions).
- `optionDependencies.json` restricts select options after another option has been selected.
- `fieldOptionDependencies.json` controls field visibility based on selected options (OR across multiple options, AND with fieldDependencies when both are set).
- `onSelectedChange` updates the selected option and automatically causes newly visible dependent fields to render on the next state update.

## Development Notes

- Keep JSON file names stable because consuming systems may rely on them.
- Treat `value` in `fieldOptions.json` as a stable slug for integrations.
- Use translation ids instead of duplicating localized strings.
- If a field is reference-copied into multiple categories, changes to that field affect all references.
- Use local delete when a category or field should be removed from the current context without removing shared references elsewhere.
- `fieldDependencies` with `includeWhen` is used for boolean-controlled field visibility.
- `fieldOptionDependencies` uses OR logic per field; combined with `fieldDependencies`, AND logic applies.
- Removing a select field's type strips its options and cleans up related `optionDependencies` and `fieldOptionDependencies`.
