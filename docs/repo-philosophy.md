# Repository Design Philosophy

## Purpose

This document describes how this repository should evolve at the repository-design level: build structure, language boundaries, dependency ownership, development environments, packaging, automation, and CI.

It is not a folder map, command reference, or manifest of the current tools and outputs.
The README and the repository itself show the current mechanics. This document explains the
principles that should keep those mechanics coherent as tools change.

This repository is a mixed C++ and Python project. The C++ library is the
portable core, with optional language bindings, applications, providers, and
workflow layers around it. Those layers are useful only when they preserve the
core project's independence and keep their own responsibilities distinct.

---

## 1. Build the repository in layers

The repository should be understandable as an onion of increasingly optional
dependencies and workflow tools:

```text
Project and workflow onion:
    Native C++ core: CMake, a C++ toolchain, and native dependencies
        -> Optional Python binding and packaging
            -> Python applications and dependencies
                -> Developer workflow and quality tools: formatting, linting, and automation

Provisioning models:
    Selective: host-provided native tools, Python and uv, optional mise
    Holistic: Nix packages and `nix develop`
```

Inner layers describe what the project is. Outer layers make it easier to
provision, build, test, package, format, or verify. An outer workflow tool may
depend on inner layers or on other workflow tools, so having Just available does
not imply that every recipe is available.

Contributors may provide the layers manually or through an optional provisioning
model. A provisioning model may make the outer layers holistic and reproducible,
but it must not make itself a prerequisite of the core project.

The layers express a direction of authority, not a sequence every workflow must traverse. An outer layer may delegate directly to the appropriate inner layer.

The important rule is:

> An outer layer should invoke, provision, validate, or package an inner layer. It should not redefine the inner layer independently.

For this repository, the project descriptions should remain authoritative for
the native target graph and Python package. Providers, workflow tools, IDE
integration, and CI should compose or provide those workflows, not replace them
with parallel models.

---

## 2. Keep the portable core available through standard interfaces

The project should remain usable through ordinary C++ and Python ecosystem entry points.

The C++ side should be buildable and consumable through CMake. The Python side should be installable through standard Python packaging metadata and should use the normal Python build frontend/backend flow. Optional tools may make these paths more convenient, reproducible, or automated, but they should not become mandatory unless that is an explicit repository decision.

This does not mean every workflow must be equally pleasant without optional tooling. A developer may need to provide a compiler, dependencies, Python, or package managers manually. The requirement is that the underlying workflow remains visible and reproducible without needing to reverse-engineer a convenience layer.

---

## 3. Give each concern one authoritative owner

Every important concern should have one place that owns its meaning.

Ownership follows semantic boundaries rather than tool names. The core project
owns its targets, interfaces, package metadata, and required behavior. An
integration or provisioning layer owns the translation, environment, packaging,
or workflow needed to expose that core through its ecosystem. A workflow may
delegate to another owner, but it should not quietly become a second authority
for the same concern.

The exact tools may evolve, but the ownership boundaries matter. An outer layer may call an owner, configure it, or translate its metadata for a specific ecosystem. It should not maintain a second manual description of the same sources, targets, dependencies, or test behavior.

A useful test is:

> If this value or behavior changes, must several manually maintained places be edited for the repository to remain correct?

If yes, the repository probably has duplicated authority.

---

## 4. Prefer delegation over reimplementation

Tools should delegate meaningful work to the layer that owns it.

Good delegation in this repository looks like:

- CI invoking repository-owned build and test workflows.
- Python packaging invoking the native build through the configured backend rather than carrying its own native target graph.
- An integration or provisioning layer deriving from the same project semantics
  while adapting them to its ecosystem.
- Just recipes composing common workflows and CMake presets selecting common configurations without becoming independent build systems.
- Formatting and other quality workflows delegating to one owner for each
  semantic layer, rather than composing competing policies.

Repeated commands or values are not automatically bad. Lockfiles, generated metadata, platform-specific package expressions, and CI matrix entries may repeat information for good reasons. The problem is manual, competing authority.

When two workflows produce the same artifact, they should either share the same authoritative metadata or serve clearly different use cases. If they cannot be kept aligned, prefer one canonical path and let other tools invoke it.

---

## 5. Let CMake describe project semantics, not caller policy

CMake should define what must be true for the native project graph to be correct.

It should normally own:

- Which C++ libraries, applications, examples, tests, and extension modules exist.
- Which sources belong to each target.
- Public and private interfaces.
- Required language features.
- Link relationships and compile definitions required by the targets.
- Project options that select meaningful components.
- Logical installation and package export behavior.

CMake should normally avoid imposing caller, developer, or packager policy:

- Compiler selection.
- Dependency provider selection.
- Optimization level.
- Warnings-as-errors.
- Sanitizers, coverage, or profiling modes.
- Link-time optimization and CPU-specific tuning.
- Installation prefix and distribution-specific paths.
- Machine-local tool locations.

The boundary is not whether a setting affects the generated binary. A required link relationship belongs to the project. An aggressive warning policy or sanitizer configuration belongs to the caller. The project owns what the graph means; the caller owns how that graph is built for a particular environment or purpose.

---

## 6. Separate dependency declaration from dependency provisioning

The project should declare the dependencies it needs. Providers should decide how those dependencies are obtained.

CMake may declare a native dependency through standard package discovery. Python packaging may declare Python build and runtime requirements. Those dependencies may then be supplied by vcpkg, uv, Nix, a system package manager, a toolchain file, a configured prefix, or another provider.

Native toolchain and Python/uv versions are intentionally caller-selectable.
Mise's defaults are optional conveniences for miscellaneous tools, not
universal toolchain authority. Nix is the all-in alternative when a complete
environment is desired.

Provider-specific metadata is legitimate. Different ecosystems need their own names, locks, and translation rules. The important distinction is:

- The project declares the semantic dependency.
- The provider supplies an implementation of that dependency.

Provider lock-in may be acceptable when deliberate. It should not be hidden inside configuration that appears to be generic.

---

## 7. Keep semantic categories distinct

Repository organization should reflect what things are, not just how they are built.

The main categories in this project are:

- A reusable C++ library with a public consumption story.
- A Python extension and applications built on top of that native core.
- Examples that demonstrate use.
- Tests and consumer checks that verify behavior and packaging.
- Development, packaging, and environment tooling.

These categories should not leak into one another accidentally. An example should not silently become an installed product. A test target should not become part of the public package. A Python helper that is internal to the application layer should not be treated as a stable public API without an explicit decision.

Clear categories make it easier to change folder layout later without changing the repository's meaning.

---

## 8. Keep environment, packaging, and CI as outer layers

Development environments should provide tools, dependencies, runtimes, and useful variables. They should not secretly redefine the project workflow.

In this repository, Nix is an optional outer integration layer. Its files and
behavior should describe how the project is provisioned, packaged, developed,
or run through Nix; they should not redefine the core project or require Nix in
the core workflows. The core should remain usable without Nix, and Nix should
remain self-contained at the boundary around it. If the repository later adds a
genuinely Nix-native component, that should be an explicit change to the
project's semantic layers rather than an accidental leak from this integration.

Packaging may translate project metadata for a target ecosystem. It may need sandboxing, lock interpretation, patched paths, split outputs, or platform-specific fixes. That is acceptable when the package still represents the same project semantics.

CI should provision platforms, select toolchains, invoke repository-owned workflows, collect results, and report failures. It should not be the only place where the build or test logic exists.

A contributor should be able to run the meaningful checks locally with reasonable effort. Remote automation may be broader, stricter, or more reproducible, but it should not be mysterious.

---

## 9. Make state and automation explicit

Generated files may be committed when that improves reproducibility, reviewability, or tool compatibility. They should remain generated state, not manually maintained authority.

Build trees, virtual environments, package-manager caches, generated sources, and lockfiles are often configuration-specific. The repository should make cleanup and refresh boundaries clear when state cannot be safely reused across compilers, dependency providers, Python versions, build types, or platforms.

Automation is valuable when it removes real friction. It becomes harmful when entering a directory, importing a module, running a convenience command, or reusing a build directory performs surprising work. Prefer explicit commands and visible state transitions when failure modes matter.

---

## 10. Evolve deliberately

Tools may be added, removed, or replaced. C++ and Python responsibilities may shift. Packaging formats and development environments may change.

Changes should preserve these principles:

1. Identify the authoritative owner of the concern being changed.
2. Keep standard C++ and Python workflows available.
3. Make outer layers delegate to inner layers.
4. Avoid manually synchronized authorities.
5. Keep CMake focused on project semantics and callers focused on policy.
6. Keep dependency declaration separate from provisioning.
7. Keep CI and packaging derived from repository-owned behavior.
8. Prefer explicit behavior over hidden automation.
9. Keep provisioning and integration models optional. No provider should become a hidden requirement of the core project.
10. Remove superseded workflows rather than preserving ambiguous alternatives.
11. Update this philosophy only when the intended architecture changes, not when filenames or command spellings change.
