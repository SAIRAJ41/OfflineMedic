# Graph Report - OfflineMedic  (2026-05-02)

## Corpus Check
- 16 files · ~39,784 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 73 nodes · 63 edges · 11 communities detected
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]

## God Nodes (most connected - your core abstractions)
1. `package:flutter/material.dart` - 6 edges
2. `GeneratedPluginRegistrant` - 2 edges
3. `../models/triage_result.dart` - 2 edges
4. `MainActivity` - 1 edges
5. `OfflineMedicApp` - 1 edges
6. `main` - 1 edges
7. `build` - 1 edges
8. `MaterialApp` - 1 edges
9. `screens/input/input_screen.dart` - 1 edges
10. `TriageResult` - 1 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Communities

### Community 0 - "Community 0"
Cohesion: 0.12
Nodes (15): analyze, build, Center, Expanded, _inputCard, InputScreen, _InputScreenState, Row (+7 more)

### Community 1 - "Community 1"
Cohesion: 0.2
Nodes (9): build, Center, EmergencyScreen, GestureDetector, Scaffold, _SecondaryButton, SizedBox, Spacer (+1 more)

### Community 2 - "Community 2"
Cohesion: 0.2
Nodes (9): build, GestureDetector, HomeScreen, _HomeScreenState, Icon, Scaffold, severityColor, SizedBox (+1 more)

### Community 3 - "Community 3"
Cohesion: 0.22
Nodes (8): build, Container, _hospitalItem, Icon, MapScreen, Padding, Scaffold, SizedBox

### Community 4 - "Community 4"
Cohesion: 0.33
Nodes (5): build, main, MaterialApp, OfflineMedicApp, screens/input/input_screen.dart

### Community 5 - "Community 5"
Cohesion: 0.4
Nodes (4): main, package:flutter/material.dart, package:flutter_test/flutter_test.dart, package:offline_medic/main.dart

### Community 6 - "Community 6"
Cohesion: 0.67
Nodes (1): GeneratedPluginRegistrant

### Community 7 - "Community 7"
Cohesion: 0.67
Nodes (2): GemmaService, ../models/triage_result.dart

### Community 8 - "Community 8"
Cohesion: 1.0
Nodes (1): MainActivity

### Community 9 - "Community 9"
Cohesion: 1.0
Nodes (1): TriageResult

### Community 10 - "Community 10"
Cohesion: 1.0
Nodes (1): DummyData

## Knowledge Gaps
- **53 isolated node(s):** `MainActivity`, `OfflineMedicApp`, `main`, `build`, `MaterialApp` (+48 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 6`** (3 nodes): `GeneratedPluginRegistrant.java`, `GeneratedPluginRegistrant`, `.registerWith()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 7`** (3 nodes): `GemmaService`, `gemma_service.dart`, `../models/triage_result.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 8`** (2 nodes): `MainActivity.kt`, `MainActivity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 9`** (2 nodes): `TriageResult`, `triage_result.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 10`** (2 nodes): `DummyData`, `dummy_data.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `Community 5` to `Community 0`, `Community 1`, `Community 2`, `Community 3`, `Community 4`?**
  _High betweenness centrality (0.522) - this node is a cross-community bridge._
- **Why does `../models/triage_result.dart` connect `Community 7` to `Community 0`?**
  _High betweenness centrality (0.044) - this node is a cross-community bridge._
- **What connects `MainActivity`, `OfflineMedicApp`, `main` to the rest of the system?**
  _53 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.12 - nodes in this community are weakly interconnected._