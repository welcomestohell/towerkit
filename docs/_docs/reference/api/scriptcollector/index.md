---
hide:
    - toc
---

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
<h3 id="method.new" markdown>
    `#!luau function new(): ()`
</h3>

Constructs an empty ScriptCollector.


<h3 id="method.clone" markdown>
    `#!luau function clone(self: ScriptCollector): ScriptCollector`
</h3>

Constructs a new ScriptCollector keeping it's collected scripts. Levels,
for example, clones a base ScriptCollector with core scripts.


<h3 id="method.collectmodulescript" markdown>
    `#!luau function collectModuleScript(self: ScriptCollector, instance: ModuleScript): ()`
</h3>

Processes a ModuleScript instance, collecting MechanicImplementations if it
is returned from the module.


<h3 id="method.collectinstance" markdown>
    `#!luau function collectInstance(self: ScriptCollector, instance: Instance): ()`
</h3>

Processes a given Instance. If it is a ModuleScript, it is deferred to
`ScriptCollector.collectModuleScript`.


<h3 id="method.collectinstanceasync" markdown>
    `#!luau function collectInstanceAsync(self: ScriptCollector, instance: Instance): Promise`
</h3>

Processes a given Instance. If it is a ModuleScript, it is deferred to
`ScriptCollector.collectModuleScript`.

Returns a Promise, which can be used with `Promise.all` to collect many
instances parallel.


<h3 id="method.collectinstancesasync" markdown>
    `#!luau function collectInstancesAsync(self: ScriptCollector, instances: { Instance }): Promise`
</h3>

Collects many instances in parallel.



