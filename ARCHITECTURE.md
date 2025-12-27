# MacCleaner Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           MacCleaner CLI                                 │
│                         (Main Entry Point)                               │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                ┌────────────────┴────────────────┐
                │                                  │
    ┌───────────▼──────────┐          ┌──────────▼───────────┐
    │   Command Router     │          │   Configuration      │
    │  (Argument Parser)   │◄─────────┤    Manager          │
    └───────────┬──────────┘          └──────────────────────┘
                │
    ┌───────────┼───────────┬─────────────┬──────────────┬──────────┐
    │           │           │             │              │          │
┌───▼───┐  ┌───▼────┐  ┌──▼───┐  ┌──────▼─────┐  ┌────▼─────┐  ┌─▼──┐
│ Scan  │  │ Clean  │  │Resume│  │   Status   │  │  Stats   │  │Cfg │
└───┬───┘  └───┬────┘  └──┬───┘  └──────┬─────┘  └────┬─────┘  └─┬──┘
    │          │           │             │              │          │
    └──────────┴───────────┴─────────────┴──────────────┴──────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
         ┌──────────▼─────────┐    ┌─────────▼──────────┐
         │   Core Services    │    │   Data Managers    │
         └────────────────────┘    └────────────────────┘
```

## Component Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│                         PRESENTATION LAYER                              │
├────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────────────────┐ │
│  │ Interactive  │  │   Results    │  │       Utilities             │ │
│  │    Mode      │  │   Display    │  │  (Formatting, Helpers)      │ │
│  └──────────────┘  └──────────────┘  └─────────────────────────────┘ │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
                                  │
┌─────────────────────────────────┴───────────────────────────────────────┐
│                          BUSINESS LOGIC LAYER                            │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐  ┌────────────┐  │
│  │   File      │  │   Cache      │  │   Storage    │  │ Configuration│
│  │  Scanner    │  │  Cleaner     │  │   Manager    │  │   Manager   │  │
│  │             │  │              │  │              │  │             │  │
│  │ • Scan      │  │ • User cache │  │ • Move files │  │ • Load/Save │  │
│  │ • Filter    │  │ • System     │  │ • Archive    │  │ • Defaults  │  │
│  │ • Analyze   │  │ • Browser    │  │ • Organize   │  │ • Paths     │  │
│  └─────────────┘  └──────────────┘  └──────────────┘  └────────────┘  │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
                                  │
┌─────────────────────────────────┴───────────────────────────────────────┐
│                         INFRASTRUCTURE LAYER                             │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌─────────────┐  ┌──────────────┐                                     │
│  │   Logger    │  │   Journal    │                                     │
│  │   (Actor)   │  │   (Actor)    │                                     │
│  │             │  │              │                                     │
│  │ • Console   │  │ • Track ops  │                                     │
│  │ • JSON logs │  │ • Resume     │                                     │
│  │ • Levels    │  │ • Statistics │                                     │
│  └─────────────┘  └──────────────┘                                     │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
                                  │
┌─────────────────────────────────┴───────────────────────────────────────┐
│                          FILE SYSTEM LAYER                               │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │                     FileManager (Foundation)                        │ │
│  │                                                                     │ │
│  │  • File operations    • Volume management    • Permissions        │ │
│  │  • Enumeration        • Resource values      • Attributes         │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

## Data Flow: Scan Operation

```
┌─────────────┐
│    User     │
│ CLI Command │
└──────┬──────┘
       │
       │ maccleaner scan --threshold 500
       │
       ▼
┌─────────────────┐
│ Argument Parser │
└──────┬──────────┘
       │
       │ Parse options
       │
       ▼
┌─────────────────┐          ┌──────────────┐
│  Scan Command   │◄─────────┤ Config Load  │
└──────┬──────────┘          └──────────────┘
       │
       │ Initialize scanner
       │
       ▼
┌─────────────────┐          ┌──────────────┐
│  File Scanner   │─────────►│    Logger    │
│                 │  Log ops │   (Actor)    │
└──────┬──────────┘          └──────────────┘
       │
       │ Enumerate files
       │
       ├─► For each file/directory:
       │   ┌──────────────────────────┐
       │   │ 1. Check size            │
       │   │ 2. Check exclude list    │
       │   │ 3. Get metadata          │
       │   │ 4. Categorize            │
       │   │ 5. Add to results        │
       │   └──────────────────────────┘
       │
       ▼
┌─────────────────┐
│  Scan Results   │
│                 │
│ • Files list    │
│ • Total size    │
│ • Statistics    │
└──────┬──────────┘
       │
       │ Display results
       │
       ▼
┌─────────────────┐
│ Results Display │
│                 │
│ • Format output │
│ • Show stats    │
│ • File details  │
└──────┬──────────┘
       │
       │ Enter interactive mode
       │
       ▼
┌─────────────────────────────────────────┐
│         Interactive File Manager        │
│                                         │
│  For each file:                         │
│  ┌────────────────────────────────────┐ │
│  │ Show: Size, Age, Suggestion        │ │
│  │                                    │ │
│  │ Ask: [s]torage [f]ast [d]elete   │ │
│  └────────────────┬───────────────────┘ │
│                   │                     │
└───────────────────┼─────────────────────┘
                    │
      ┌─────────────┼─────────────┬─────────────┬──────────┐
      │             │             │             │          │
 [s] Move      [f] Move      [d] Delete    [k] Skip   [q] Quit
      │             │             │             │          │
      ▼             ▼             ▼             ▼          ▼
┌──────────┐  ┌──────────┐  ┌──────────┐  Continue   Exit
│ Storage  │  │   Fast   │  │  Delete  │
│ Manager  │  │ Storage  │  │ Confirm  │
└─────┬────┘  └─────┬────┘  └─────┬────┘
      │             │             │
      │  ┌──────────┴─────────────┘
      │  │
      ▼  ▼
┌──────────────┐          ┌──────────────┐
│   Journal    │─────────►│    Logger    │
│   (Actor)    │  Log op  │   (Actor)    │
└──────┬───────┘          └──────────────┘
       │
       │ Track operation
       │
       ▼
┌──────────────┐
│  Perform     │
│  Operation   │
│              │
│ • Move file  │
│ • Update     │
│   journal    │
└──────────────┘
```

## Data Flow: Clean Operation

```
┌─────────────┐
│    User     │
└──────┬──────┘
       │ maccleaner clean --user-caches --dry-run
       │
       ▼
┌─────────────────┐
│ Clean Command   │
└──────┬──────────┘
       │
       ▼
┌─────────────────┐          ┌──────────────┐
│ Cache Cleaner   │─────────►│    Logger    │
└──────┬──────────┘          └──────────────┘
       │
       │ Identify cache directories
       │
       ├─► User Caches:
       │   • ~/Library/Caches
       │   • ~/Library/Logs
       │   • ~/Library/Application Support/CrashReporter
       │
       ├─► For each cache:
       │   ┌──────────────────────────┐
       │   │ 1. Check if exists       │
       │   │ 2. Calculate size        │
       │   │ 3. Check skip list       │
       │   │ 4. If not dry-run:       │
       │   │    - Create journal      │
       │   │    - Delete              │
       │   │    - Update journal      │
       │   │ 5. Log results           │
       │   └──────────────────────────┘
       │
       ▼
┌─────────────────┐
│  Report Results │
│                 │
│ • Total cleaned │
│ • Errors        │
│ • Time taken    │
└─────────────────┘
```

## Storage Flow

```
┌────────────────────────────────────────────────────────────────────┐
│                        Local Mac Storage                           │
│                                                                    │
│  /Users/username/                                                 │
│    ├── Downloads/        ◄────┐                                  │
│    ├── Documents/             │ SCAN                             │
│    ├── Desktop/               │                                  │
│    └── Movies/                │                                  │
│                               │                                  │
└───────────────────────────────┼───────────────────────────────────┘
                                │
                                │
                    ┌───────────▼──────────┐
                    │    File Scanner      │
                    │                      │
                    │ • Find large files   │
                    │ • Analyze metadata   │
                    │ • Categorize         │
                    └───────────┬──────────┘
                                │
                                │
                    ┌───────────▼──────────┐
                    │  Interactive Mode    │
                    │                      │
                    │ User chooses action  │
                    └──┬────────────────┬──┘
                       │                │
            ┌──────────┘                └──────────┐
            │                                      │
            ▼                                      ▼
┌──────────────────────┐              ┌──────────────────────┐
│  Archive Storage     │              │   Fast Storage       │
│  (HDD)               │              │   (NVMe)            │
│                      │              │                      │
│  /Volumes/storage1/  │              │  /Volumes/flash1/    │
│    └── Archive/      │              │    └── [files]       │
│        └── 2024/     │              │                      │
│            └── 12/   │              │  For frequently      │
│                      │              │  accessed files      │
│  Large, old, media   │              │                      │
│  files automatically │              │                      │
│  organized by date   │              │                      │
└──────────────────────┘              └──────────────────────┘
```

## Actor Concurrency Model

```
┌────────────────────────────────────────────────────────────────────┐
│                       Main Thread (CLI)                            │
└────────────────────────────────┬───────────────────────────────────┘
                                 │
                                 │ Async/Await calls
                                 │
                 ┌───────────────┼───────────────┐
                 │               │               │
        ┌────────▼────────┐ ┌───▼───────┐ ┌────▼──────────┐
        │  Logger Actor   │ │  Journal  │ │ FileScanner   │
        │                 │ │   Actor   │ │    Actor      │
        │ • Serial queue  │ │           │ │               │
        │ • Log entries   │ │ • Serial  │ │ • Concurrent  │
        │ • File writes   │ │ • Ops     │ │   scanning    │
        └─────────────────┘ └───────────┘ └───────────────┘
                │                  │              │
                └──────────────────┴──────────────┘
                           │
                           │ Thread-safe communication
                           │
                ┌──────────▼──────────┐
                │  Shared State       │
                │                     │
                │ • Operations list   │
                │ • Statistics        │
                │ • Configuration     │
                └─────────────────────┘
```

## File Organization Structure

```
MacCleaner Data Directories:

~/Library/Application Support/MacCleaner/
├── logs/
│   ├── maccleaner_2024-12-27_10-30-00.log
│   ├── maccleaner_2024-12-27_11-15-00.log
│   └── maccleaner_2024-12-27_14-45-00.log
│
├── journal/
│   ├── session_abc123.json
│   ├── session_def456.json
│   └── session_ghi789.json (current, incomplete)
│
└── config.json


Archive Storage Organization:

/Volumes/storage1/
└── Archive/
    ├── 2024/
    │   ├── 10/
    │   │   ├── large-video1.mp4
    │   │   └── old-project.zip
    │   ├── 11/
    │   │   ├── disk-image.dmg
    │   │   └── backup.tar.gz
    │   └── 12/
    │       ├── movie.mov
    │       └── presentation.key
    └── 2025/
        └── ...


Fast Storage:

/Volumes/flash1/
├── active-project/
├── current-video.mp4
└── working-files/
```

## Error Handling Flow

```
┌────────────────┐
│   Operation    │
└────────┬───────┘
         │
         │ Try operation
         │
         ▼
    ┌────────┐
    │Success?│
    └───┬────┘
        │
    ┌───┴───┐
    │       │
   Yes     No
    │       │
    │       ▼
    │   ┌──────────────┐
    │   │ Catch Error  │
    │   └──────┬───────┘
    │          │
    │          ├─► Log error
    │          ├─► Update journal (failed)
    │          ├─► Display user message
    │          └─► Continue or abort
    │
    ▼
┌───────────────┐
│ Update        │
│ Journal       │
│ (completed)   │
└───────────────┘
    │
    ▼
┌───────────────┐
│ Log success   │
└───────────────┘
    │
    ▼
┌───────────────┐
│ Continue      │
└───────────────┘
```

## Configuration Cascade

```
┌─────────────────┐
│  Default Config │
│  (hardcoded)    │
└────────┬────────┘
         │
         │ Loaded at app init
         │
         ▼
┌─────────────────┐
│   User Config   │───► ~/Library/Application Support/MacCleaner/config.json
│   (JSON file)   │
└────────┬────────┘
         │
         │ Overrides defaults
         │
         ▼
┌─────────────────┐
│  CLI Arguments  │───► --threshold 500
│  (runtime)      │     --path ~/Downloads
└────────┬────────┘
         │
         │ Overrides config file
         │
         ▼
┌─────────────────┐
│  Final Values   │
│  Used by app    │
└─────────────────┘
```

This architecture provides:
- **Separation of concerns**: Each component has a specific responsibility
- **Thread safety**: Actors prevent race conditions
- **Resumability**: Journal system enables crash recovery
- **Configurability**: Multiple configuration layers
- **Observability**: Comprehensive logging
- **User control**: Interactive mode for decisions
