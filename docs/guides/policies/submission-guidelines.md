# Submission Guidelines

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED",  "MAY", and "OPTIONAL" in this document are to be
interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119).

## Tower Building

### 1. Platform

Towers MUST be made in Roblox Studio using the official Welcome To Hell Kit.

1.  Towers MUST be built starting with the latest available version of the kit.
2.  Towers are RECOMMENDED to be up-to-date with the latest kit version using
    update kits.

### 2. Instance Limit

Each floor MUST NOT exceed 1500 instances across Mechanics, Obby, Frame, and
Decorations.

1.  This limit MUST be enforced by individual floors.
2.  This limit MUST NOT be enforced with the tower as a whole.
3.  Folders MUST NOT be counted to a floor's instance limit.
4.  It is RECOMMENDED to organize floors using Folders across Mechanics, Obby,
    Frame, and Decorations.

### 3. User Scripting

Towers SHALL only implement custom logic as ModuleScripts placed under it's
Scripts folder.

1.  Towers MAY include external packages and modules so long it is placed under
    the Scripts folder.
2.  Towers MAY implement it's own Mechanics.
3.  Internals and built-in Scripts MUST NOT be modified.
4.  Built-in Mechanics MAY be modified using a new Mechanic under it's Scripts
    folder and the `MechanicImplementation:override({})` API.
5.  Lighting effects MUST be done using the `LightingProvider` provider.
6.  Towers MUST NOT use scripts from free models, including gears.

### 4. Artificial Intelligence

Towers MUST NOT include any form of generative artificial intelligence in its
final submission.

1.  Builders MAY use LLMs for learning, referencing, or understanding concepts.
2.  All parts of a final submission MUST NOT be made by AI, including but not
    limited to:

    1. Code
    2. Written text (ie. dialog, signage)
    3. Models or meshes
    4. Textures or images
    5. Audio

## Frames

### 1. Floor Definition

Floors are RECOMMENDED to be 100x100x100 cubes in size.

1.  Floors MAY be moved or rotated into orientations that differ from the
    default frame.
2.  Floors MAY be expanded by up to 100 studs along the X and Z axes
    (maximum 300 studs in length per axis)
3.  Gameplay MAY be placed beyond a floor's boundaries without regard to
    dimensions.
4.  Sections smaller or equal than 50 studs in any axes CANNOT be considered
    floors and MUST NOT be included in it's total floor count, ie. droppers,
    small basements.

### 2. Floor Counts

The total floor count must fall within the allowed range for each tower type.
    
1.  Towers MUST be exactly 10 floors.
2.  Citadels MUST be between 15 to 30 floors.

### 3. Gauntlet Floor

All towers must include a separate Gauntlet floor which is used for its
chapter’s Gauntlet.

1.  This floor MUST be precisely 100 studs tall.
2.  This floor MUST comply with Section 1 (Floor Definition).
3.  This floor MUST have a clear start point and ending point which is contained
    inside the frame.
4.  This floor MUST NOT have a ceiling or a roof.
5.  This floor MUST NOT be connected with the main tower.
6.  This floor MUST NOT be included with the total floor count.

### 4. Presentation

Towers MUST have a presentable frame which is used for it's prospective
chapter's lobby.

1.  A placeholder frame MAY BE used in place of the actual frame.
2.  Gameplay does not need to be contained in a frame.
3.  Exactly ONE continous portion of a frame, at least 50 studs in width and
    depth MUST be touching the ground.

    ??? success "Valid examples"

        ![](/assets/media/frame-1.png)
        ![](/assets/media/frame-2.png)


4.  Presented frames are RECOMMENDED to feel like a tower with vertically
    stacked floors.

## Tower Place

TBA

## Tower Submission

TBA

### Naming

Towers MUST follow the format `[Tower Type] of [...]`, where `[...]` can include
up to 5 words.

1.  Names MUST NOT conflict with the acronym of a tower already in Welcome To
    Hell
2.  Names MUST NOT conflict with the following reserved tower acronyms:
    1. ToWITOL
    2. CoTFT
    3. CoWTH
3.  Names SHOULD represent the tower as a whole.
4.  Names SHOULD NOT be based on an acronym
