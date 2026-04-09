<!--
    This file was automatically @generated using Welcome To Hell's `refgen`. 
    As changes may be overriden, this file should not be manually modified.
-->

# Level

```luau
local Level = require("@game/ReplicatedStorage/Libs/Level")
```

Orchestrator of scripts and mechanics in levels.

Levels can be traversed by the player with mechanics, level scripts, and
some starting positions. Alongside towers, Levels are also used to represent
Chapters in Welcome To Hell's Campaign.

This class should not be constructed by tower scripts. Many <a href="/reference/libraries/mechanic">Mechanic</a>
methods provide a handle to a tower's Level as the last argument.

## API

{api}

