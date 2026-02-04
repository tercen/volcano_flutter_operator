# Volcano Plot Flutter App - Functional Specification

**Version:** 1.0.0
**Status:** Draft
**Last Updated:** 2026-02-03
**Reference Implementation:** `_local/volcano_shiny/` (R-Shiny)

---

## 1. Overview

### 1.1 Purpose

The Volcano Plot app is an interactive data visualisation tool for differential expression analysis. It displays gene expression data as a scatter plot with log2 fold change on the x-axis and -log10 p-value (significance) on the y-axis, allowing researchers to quickly identify significantly up-regulated and down-regulated genes.

### 1.2 Users

- Bioinformatics researchers
- Data scientists working with gene expression data
- Users of the Tercen analytics platform

### 1.3 Scope

**In Scope:**

- Interactive volcano plot visualisation
- Threshold-based gene classification (Unchanged/Increased/Decreased)
- Top N hit identification and labelling
- User-defined gene selection and search
- Plot customisation (aesthetics, scaling, labels)
- PDF and PNG export
- Light and dark theme support
- Tercen platform integration (mock implementation first)

**Out of Scope:**

- Statistical analysis (data comes pre-computed)
- Data editing or transformation
- Multi-plot comparisons
- Real-time collaboration features

---

## 2. Domain Context

### 2.1 Background

Volcano plots are a standard visualisation in differential expression analysis. They combine statistical significance (p-value) with magnitude of change (fold change) to help researchers identify genes that are both statistically significant AND biologically meaningful.

### 2.2 Data Source

Data originates from Tercen workflow projections. Based on production data analysis:

**Row Data (main data points)**:

| Column | Description | Example |
| ------ | ----------- | ------- |
| `.ci` | Column index (0-based) - identifies which comparison | 0, 1, 2, 3 |
| `.x` | Log2 fold change | -42.5 to +3.6 |
| `.y` | -Log10 p-value (significance) | 0.7 to 3.7 |
| `labels` | Gene/kinase names (column name is dynamic) | EGFR, JAK1, BLK |

**Column Data (comparison groups)**:

| Column | Description | Example |
| ------ | ----------- | ------- |
| Group name column | Comparison/contrast identifier | "Sgroup1_T1 vs Control" |

**Data Characteristics**:
- Multiple comparisons (volcano plots) per dataset, selectable via dropdown
- Typical dataset: 50-100 genes per comparison
- Fold change can be strongly negative (e.g., -42) or positive
- Significance values typically range 0.7 to 4.0
- Label column name is dynamic (determined by upstream workflow)

### 2.3 Typical Workflow

1. User runs differential expression analysis in Tercen
2. Results are projected onto the volcano plot operator
3. User adjusts thresholds to define "significant" genes
4. User identifies top hits by various ranking criteria
5. User searches for specific genes of interest
6. User exports publication-ready plots

---

## 3. Functional Requirements

### 3.1 Data Display

| ID | Requirement | Priority |
| -- | ----------- | -------- |
| FR-01 | Display scatter plot with fold change (x) vs significance (y) | Must |
| FR-02 | Colour points by change status: Unchanged, Increased, Decreased | Must |
| FR-03 | Show dashed threshold lines for fold change and significance | Must |
| FR-04 | Display labels for top N ranked genes | Must |
| FR-05 | Show hover tooltip with gene name, fold change, and significance | Must |
| FR-06 | Support multiple comparisons via dropdown selector | Must |

### 3.2 Threshold Controls

| ID | Requirement | Priority |
| -- | ----------- | -------- |
| FR-07 | Fold change threshold as range slider (-5 to 5, default -1.5 to 1.5) | Must |
| FR-08 | Significance threshold as slider (0 to 5, default 2.0) | Must |
| FR-09 | Highlight filter: All, Changed, Up, Down | Must |

### 3.3 Top Hits

| ID | Requirement | Priority |
| -- | ----------- | -------- |
| FR-10 | Ranking criterion selector: Manhattan, Euclidean, Fold Change, Significance | Must |
| FR-11 | Show top N input (0 = none, default 10) | Must |
| FR-12 | Gene search to add genes to highlighted list | Must |

### 3.4 Appearance

| ID | Requirement | Priority |
| -- | ----------- | -------- |
| FR-13 | Point size slider (1-10, default 4) | Must |
| FR-14 | Opacity slider (0-100%, default 80%) | Must |
| FR-15 | Text scale slider (50-200%, default 100%) - scales all plot text proportionally | Must |
| FR-16 | Gridlines toggle | Should |
| FR-17 | Legend with dismiss (✕) button, on by default | Must |
| FR-18 | Reset button - restores legend and resets appearance to defaults | Should |

### 3.5 Axes

| ID | Requirement | Priority |
| -- | ----------- | -------- |
| FR-19 | X min/max inputs (empty = auto-scale) | Should |
| FR-20 | Y min/max inputs (empty = auto-scale) | Should |
| FR-21 | Y log scale toggle | Should |
| FR-22 | Rotate axes toggle (swap X/Y) | Could |

### 3.6 Plot Labels (In-Plot Editing)

| ID | Requirement | Priority |
| -- | ----------- | -------- |
| FR-23 | Editable title - greyed placeholder, click to edit, blank if unchanged on export | Should |
| FR-24 | Editable X-axis label - greyed placeholder "Fold Change (Log₂)", click to edit, prints default if unchanged | Must |
| FR-25 | Editable Y-axis label - greyed placeholder "Significance (-Log₁₀)", click to edit, prints default if unchanged | Must |
| FR-26 | Click point to add/remove label | Should |
| FR-27 | Click existing label to edit or delete | Should |

### 3.7 Export

| ID | Requirement | Priority |
| -- | ----------- | -------- |
| FR-28 | Download as PDF button (in left panel) | Must |
| FR-29 | Download as PNG button (in left panel) | Must |
| FR-30 | Export width/height inputs | Should |

### 3.8 Info

| ID | Requirement | Priority |
| -- | ----------- | -------- |
| FR-31 | GitHub repository link (replaces About section) | Must |

---

## 4. User Interface Components

### 4.1 App Structure

The app follows the Tercen app-frame pattern with **no controls in the main panel** (all controls in left panel):

```
┌─────────────────────────────────────────────────────────────┐
│ Left Panel (280px)       │ Main Panel (flex: 1)             │
│                          │                                  │
│ ┌──────────────────────┐ │  Click to add title (greyed)     │
│ │ Panel Header         │ │ ┌──────────────────────────────┐ │
│ │ - App icon           │ │ │                              │ │
│ │ - "Volcano Plot"     │ │ │        ●    ┌─────────────┐  │ │
│ │ - Theme toggle 🌙    │ │ │    ●      ● │ Legend    ✕ │  │ │
│ │ - Collapse ◀         │ │ │  ●   ● ●    │ ● Unchanged │  │ │
│ └──────────────────────┘ │ │ ════════════│ ● Increased │  │ │
│                          │ │  ● ● ●●●●●  │ ● Decreased │  │ │
│ ▼ Data                   │ │  ●  ●  ● ●  └─────────────┘  │ │
│ ┌──────────────────────┐ │ │                              │ │
│ │ Comparison [▼]       │ │ │                              │ │
│ └──────────────────────┘ │ └──────────────────────────────┘ │
│                          │  Fold Change (Log₂) (greyed)     │
│ ▼ Thresholds             │                                  │
│ ┌──────────────────────┐ │         │                        │
│ │ Fold Change [--●--]  │ │         │ Significance (-Log₁₀)  │
│ │ Significance [--●--] │ │         │ (greyed, rotated)      │
│ │ Highlight [▼]        │ │                                  │
│ └──────────────────────┘ │ ┌──────────────────────────────┐ │
│                          │ │ Tooltip (on hover)           │ │
│ ▼ Top Hits               │ │ Gene: BLK                    │ │
│ ┌──────────────────────┐ │ │ FC: 3.24, Sig: 3.67          │ │
│ │ Ranking [▼]          │ │ └──────────────────────────────┘ │
│ │ Show top [10]        │ │                                  │
│ │ Search genes [____]  │ │                                  │
│ └──────────────────────┘ │                                  │
│                          │                                  │
│ ▼ Appearance             │                                  │
│ ┌──────────────────────┐ │                                  │
│ │ Point size [--●--]   │ │                                  │
│ │ Opacity [--●--]      │ │                                  │
│ │ Text scale [--●--]   │ │                                  │
│ │ Gridlines [  ]       │ │                                  │
│ │ [Reset]              │ │                                  │
│ └──────────────────────┘ │                                  │
│                          │                                  │
│ ▼ Axes                   │                                  │
│ ┌──────────────────────┐ │                                  │
│ │ X min [__] max [__]  │ │                                  │
│ │ Y min [__] max [__]  │ │                                  │
│ │ Y log scale [  ]     │ │                                  │
│ │ Rotate axes [  ]     │ │                                  │
│ └──────────────────────┘ │                                  │
│                          │                                  │
│ ▼ Export                 │                                  │
│ ┌──────────────────────┐ │                                  │
│ │ [Download PDF]       │ │                                  │
│ │ [Download PNG]       │ │                                  │
│ │ Width [750] H [600]  │ │                                  │
│ └──────────────────────┘ │                                  │
│                          │                                  │
│ ▼ Info                   │                                  │
│ ┌──────────────────────┐ │                                  │
│ │ 🔗 GitHub            │ │                                  │
│ └──────────────────────┘ │                                  │
└──────────────────────────┴──────────────────────────────────┘
```

### 4.2 Left Panel Sections

#### Section 1: Data

| Control | Type | Default | Notes |
| ------- | ---- | ------- | ----- |
| Comparison | Dropdown | First group | Which volcano plot to display |

#### Section 2: Thresholds

| Control | Type | Default | Range |
| ------- | ---- | ------- | ----- |
| Fold Change | Range Slider | -1.5 to 1.5 | -5 to 5 |
| Significance | Slider | 2.0 | 0 to 5 |
| Highlight | Dropdown | "Changed" | All, Changed, Up, Down |

#### Section 3: Top Hits

| Control | Type | Default | Notes |
| ------- | ---- | ------- | ----- |
| Ranking | Dropdown | "Manhattan" | Manhattan, Euclidean, FC, Significance |
| Show top | Number Input | 10 | 0 = none |
| Search genes | Searchable Input | Empty | Adds to highlighted list |

#### Section 4: Appearance

| Control | Type | Default | Range/Notes |
| ------- | ---- | ------- | ----------- |
| Point size | Slider | 4 | 1-10 |
| Opacity | Slider | 80% | 0-100% |
| Text scale | Slider | 100% | 50-200% (scales all plot text) |
| Gridlines | Toggle | Off | On/Off |
| Reset | Button | - | Restores legend, resets appearance defaults |

#### Section 5: Axes

| Control | Type | Default | Notes |
| ------- | ---- | ------- | ----- |
| X min | Number Input | Empty | Empty = auto-scale |
| X max | Number Input | Empty | Empty = auto-scale |
| Y min | Number Input | Empty | Empty = auto-scale |
| Y max | Number Input | Empty | Empty = auto-scale |
| Y log scale | Toggle | Off | On/Off |
| Rotate axes | Toggle | Off | Swaps X and Y |

#### Section 6: Export

| Control | Type | Notes |
| ------- | ---- | ----- |
| Download PDF | Button | Exports current plot |
| Download PNG | Button | Exports current plot |
| Width | Number Input | Export width in pixels |
| Height | Number Input | Export height in pixels |

#### Section 7: Info

| Control | Type | Notes |
| ------- | ---- | ----- |
| GitHub link | Icon + Link | Links to repository |

### 4.3 Main Panel - Volcano Plot

#### Visual Elements

| Element | Appearance |
| ------- | ---------- |
| Unchanged points | Dark grey (#141A1F) |
| Increased points | Green (#57C981) |
| Decreased points | Blue (#36A2E0) |
| FC threshold lines | Dashed vertical lines |
| Significance threshold line | Dashed horizontal line |
| Top hit labels | Text with simple offset from point |
| Top hit markers | Hollow circle around point |

#### Editable Plot Labels

| Element | Default State | Appearance | Interaction | Export Behaviour |
| ------- | ------------- | ---------- | ----------- | ---------------- |
| Title | ON | Greyed: *"Click to add title"* | Click to edit | Blank if unchanged |
| X-axis label | ON | Greyed: *"Fold Change (Log₂)"* | Click to edit | Print default if unchanged |
| Y-axis label | ON | Greyed: *"Significance (-Log₁₀)"* | Click to edit | Print default if unchanged |
| Legend | ON | Box with ✕ dismiss button | Click ✕ to hide | Hidden if dismissed |

#### Point Interactions

| Interaction | Behaviour |
| ----------- | --------- |
| Hover point | Show tooltip with gene details |
| Click point | Add/remove label for that gene |
| Click label | Edit or delete the label |
| Hover label | Show delete icon |

### 4.4 Hover Tooltip

Displays on point hover:

```
┌─────────────────────┐
│ Gene: BLK           │
│ Fold Change: 3.24   │
│ Significance: 3.67  │
└─────────────────────┘
```

### 4.5 Legend Component

```
┌─────────────────┐
│ Legend        ✕ │
│ ● Unchanged     │
│ ● Increased     │
│ ● Decreased     │
└─────────────────┘
```

- Positioned in top-right of plot area
- ✕ button dismisses legend
- Re-enable via **Reset** button in Appearance section
- If dismissed, does not appear in export

---

## 5. Non-Functional Requirements

### 5.1 Performance

| ID | Requirement |
| -- | ----------- |
| NFR-01 | Handle up to 10,000 data points without lag |
| NFR-02 | Control changes reflect in plot within 100ms |
| NFR-03 | Initial load completes within 2 seconds |

### 5.2 Compatibility

| ID | Requirement |
| -- | ----------- |
| NFR-04 | Run as Tercen web operator (WASM build) |
| NFR-05 | Support Chrome, Firefox, Edge (latest versions) |
| NFR-06 | Responsive layout for various screen sizes |

### 5.3 Usability

| ID | Requirement |
| -- | ----------- |
| NFR-07 | Show loading indicator during data fetch |
| NFR-08 | Display meaningful error messages |
| NFR-09 | Support both light and dark themes |
| NFR-10 | Panel collapses to 48px icon strip |

---

## 6. Feature Summary

### Core Features (Must Have)

| Feature | Status |
| ------- | ------ |
| Volcano scatter plot | Planned |
| Point colouring by change status | Planned |
| Threshold lines (dashed) | Planned |
| Fold change range slider | Planned |
| Significance threshold slider | Planned |
| Highlight filter (All/Changed/Up/Down) | Planned |
| Comparison selector dropdown | Planned |
| Top N ranking with criterion selector | Planned |
| Gene search | Planned |
| Hover tooltip | Planned |
| Point size slider | Planned |
| Opacity slider | Planned |
| Text scale slider | Planned |
| Legend with dismiss button | Planned |
| Reset button (restores legend + defaults) | Planned |
| Editable axis labels (in-plot) | Planned |
| PDF export | Planned |
| PNG export | Planned |
| GitHub info link | Planned |
| Dark mode | Planned |
| Panel collapse (280px → 48px) | Planned |

### Secondary Features (Should Have)

| Feature | Status |
| ------- | ------ |
| Editable title (in-plot) | Planned |
| Click point to add/remove label | Planned |
| Click label to edit/delete | Planned |
| Gridlines toggle | Planned |
| Custom axis ranges (X/Y min/max) | Planned |
| Y log scale toggle | Planned |
| Export width/height inputs | Planned |

### Optional Features (Could Have)

| Feature | Status |
| ------- | ------ |
| Rotate axes toggle | Planned |

### Removed Features (vs R-Shiny)

| Feature | Reason |
| ------- | ------ |
| Hide labels checkbox | Labels now managed via click in plot |
| Nested conditional controls | All controls always visible |
| 4 separate font size inputs | Replaced with single Text Scale slider |
| About section text block | Moved to GitHub README |
| Download buttons in main panel | Moved to Export section in left panel |

---

## 7. Assumptions

### 7.1 Data Assumptions

- Input data is pre-computed (fold change and p-values already calculated)
- Gene names are provided in the `labels` projection
- P-values are already transformed to -log10 scale
- Data may contain multiple groups (column variable)
- Some grid positions may have missing data (sparse data is normal)

### 7.2 Environment Assumptions

- App runs in modern web browser with WebAssembly support
- User has authenticated to Tercen platform
- Network connection is available for initial data load
- Screen width is at least 800px

### 7.3 Mock Data

For mock implementation phase, use the provided production data samples:

**Source files** (in `_local/`):
- `example_row_data.csv` - 300 data points across 4 comparisons
- `example_column_data.csv` - 4 comparison group names

**Data characteristics from production**:
- 4 comparison groups (selectable volcano plots)
- 75 kinases per comparison
- Fold change range: -42.5 to +3.6 (note: large negative values in some groups)
- Significance range: 0.7 to 3.7
- Kinase names: EGFR, JAK1, JAK2, BLK, LCK, SRC, etc.

**Mock data mapping**:
- Row `.ci` (0-based) maps to Column `.ci` (1-based): row.ci + 1 = column.ci
- Group 0 → "Sgroup1_T1 vs Control"
- Group 1 → "Sgroup1_T2 vs Control"
- Group 2 → "Sgroup1_T2 vs T1"
- Group 3 → "Sgroup2_Test vs Control"

**Note**: The `.ci` column in column_data was added for mock clarity and won't be present in production Tercen data.

---

## 8. Glossary

| Term | Definition |
| ---- | ---------- |
| Fold Change | Ratio of expression between conditions, typically log2 transformed. Positive = up-regulated, Negative = down-regulated |
| P-value | Statistical probability that the observed difference is due to chance |
| -Log10 P-value | Transformed p-value where higher values = more significant |
| Volcano Plot | Scatter plot combining fold change (x) and significance (y) |
| Differential Expression | Analysis comparing gene expression between conditions |
| Manhattan Distance | Sum of absolute differences: \|x\| + \|y\| |
| Euclidean Distance | Straight-line distance: sqrt(x² + y²) |
| Hit | Gene that exceeds both fold change and significance thresholds |
| Tercen | Cloud-based data analytics platform |
| Operator | Tercen application/visualisation component |

---

## Appendix A: Colour Palette

| Status | Hex Code | RGB | Usage |
| ------ | -------- | --- | ----- |
| Unchanged | #141A1F | 20, 26, 31 | Points within thresholds |
| Increased | #57C981 | 87, 201, 129 | Points above FC max AND sig threshold |
| Decreased | #36A2E0 | 54, 162, 224 | Points below FC min AND sig threshold |

---

## Appendix B: Change Classification Logic

```
IF fold_change > fc_max AND significance > sig_threshold THEN
    status = "Increased"
ELSE IF fold_change < fc_min AND significance > sig_threshold THEN
    status = "Decreased"
ELSE
    status = "Unchanged"
```

Direction filter modifies display:
- **All**: Show all points, ignore thresholds for colouring
- **Changed**: Show Increased + Decreased as coloured
- **Increased**: Only colour points meeting "Increased" criteria
- **Decreased**: Only colour points meeting "Decreased" criteria

---

## Appendix C: Ranking Algorithms

### Manhattan Distance
```
rank = |fold_change| + |significance|
```

### Euclidean Distance
```
rank = sqrt(fold_change² + significance²)
```

### Fold Change
```
rank = |fold_change|
```

### Significance
```
rank = significance
```

Top N hits are selected from filtered points (based on direction), sorted by chosen criterion in descending order.

---

## Document History

| Version | Date | Author | Changes |
| ------- | ---- | ------ | ------- |
| 1.0.0 | 2026-02-03 | Claude | Initial specification based on R-Shiny analysis |
| 1.1.0 | 2026-02-03 | Claude | Redesigned UI following Tercen design principles: removed nested controls, moved labels to in-plot editing, added legend dismiss, restructured left panel into 7 sections, moved export to left panel |
| 1.2.0 | 2026-02-03 | Claude | Added Text Scale slider (50-200%) for font sizing, added Reset button in Appearance section to restore legend and defaults |
| 1.3.0 | 2026-02-03 | Claude | Reviewed against original VolcaNoseR (JoachimGoedhart) - no additional features required. Specification finalized and approved for implementation |
