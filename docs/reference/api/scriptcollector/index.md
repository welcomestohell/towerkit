<!--
    This file was automatically @generated using Welcome To Hell's `refgen`. 
    As changes may be overriden, this file should not be manually modified.
-->

# ScriptCollector

```luau
ScriptCollector = {
    new: () -> (),
    clone: (self: ScriptCollector) -> ScriptCollector,
    collectModuleScript: (self: ScriptCollector, instance: ModuleScript) -> (),
    collectInstance: (self: ScriptCollector, instance: Instance) -> (),
    collectInstanceAsync: (self: ScriptCollector, instance: Instance) -> Promise,
    collectInstancesAsync: (self: ScriptCollector, instances: { Instance }) -> Promise,
}
```

Collects mechanic implementations from module scripts for use in levels.

## Methods
### new

```luau
function ScriptCollector(): ()
```

Constructs an empty ScriptCollector.


### clone

```luau
function ScriptCollector(self: ScriptCollector): ScriptCollector
```

Constructs a new ScriptCollector keeping it's collected scripts. Levels,
for example, clones a base ScriptCollector with core scripts.


### collectModuleScript

```luau
function ScriptCollector(self: ScriptCollector, instance: ModuleScript): ()
```

Processes a ModuleScript instance, collecting MechanicImplementations if it
is returned from the module.


### collectInstance

```luau
function ScriptCollector(self: ScriptCollector, instance: Instance): ()
```

Processes a given Instance. If it is a ModuleScript, it is deferred to
`ScriptCollector.collectModuleScript`.


### collectInstanceAsync

```luau
function ScriptCollector(self: ScriptCollector, instance: Instance): Promise
```

Processes a given Instance. If it is a ModuleScript, it is deferred to
`ScriptCollector.collectModuleScript`.

Returns a Promise, which can be used with `Promise.all` to collect many
instances parallel.


### collectInstancesAsync

```luau
function ScriptCollector(self: ScriptCollector, instances: { Instance }): Promise
```

Collects many instances in parallel.



