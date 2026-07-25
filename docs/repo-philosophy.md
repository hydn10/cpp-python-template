# Repository Design Philosophy

## Purpose

This document describes how this repository should evolve at the repository-design level: build structure, language boundaries, dependency ownership, development environments, packaging, automation, and CI.

It is intended for human contributors and coding agents. It is not a folder map and it is not a command reference. The README and the repository itself show the current mechanics. This document explains the principles that should keep those mechanics coherent as tools change.

This repository is a mixed C++ and Python project. The C++ library is the portable core. Python provides application-facing wrappers and packaging around that core. CMake, Python packaging, uv, vcpkg, Nix, Just, and CI all have useful roles, but those roles should stay distinct.

---

## 1. Build the repository in layers

The repository should be understandable as a set of layers:

```text
Project semantics
    ->
Standard C++ and Python ecosystem interfaces
    ->
Developer workflow conveniences
    ->
Environment provisioning
    ->
Packaging and distribution
    ->
Continuous integration
```

Inner layers describe what the project is. Outer layers make it easier to provision, build, test, package, or verify.

The layers express a direction of authority, not a sequence every workflow must traverse. An outer layer may delegate directly to the appropriate inner layer.

The important rule is:

> An outer layer should invoke, provision, validate, or package an inner layer. It should not redefine the inner layer independently.

For this repository, CMake should remain the authoritative description of the native target graph. Python packaging should describe the Python package and delegate native extension builds through the normal native build interface. uv, vcpkg, Nix, Just, presets, activation helpers, IDE integration, and CI should compose or provide those workflows, not replace them with parallel models.

---

## 2. Keep the portable core available through standard interfaces

The project should remain usable through ordinary C++ and Python ecosystem entry points.

The C++ side should be buildable and consumable through CMake. The Python side should be installable through standard Python packaging metadata and should use the normal Python build frontend/backend flow. Optional tools may make these paths more convenient, reproducible, or automated, but they should not become mandatory unless that is an explicit repository decision.

This does not mean every workflow must be equally pleasant without optional tooling. A developer may need to provide a compiler, dependencies, Python, or package managers manually. The requirement is that the underlying workflow remains visible and reproducible without needing to reverse-engineer a convenience layer.

---

## 3. Give each concern one authoritative owner

Every important concern should have one place that owns its meaning.

Typical ownership in this repository should be:

| Concern | Owner |
| --- | --- |
| Native libraries, applications, examples, tests, install/export shape | CMake |
| Native dependency requirements | CMake package discovery and target links |
| Python package metadata, scripts, runtime dependencies | Python packaging metadata |
| Python environment synchronization | uv and its lock state |
| Shared C++ and Python project version | vcpkg manifest |
| vcpkg dependency mapping and baseline | vcpkg metadata |
| Optional developer workflow composition | Just |
| Reproducible development and package environments | Nix |
| Remote platform matrix and result reporting | CI |

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
- Nix providing compilers, dependencies, Python, and package builds while deriving from the same project metadata where practical.
- Just recipes composing common workflows and CMake presets selecting common configurations without becoming independent build systems.

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

Provider-specific metadata is legitimate. Different ecosystems need their own names, locks, and translation rules. The important distinction is:

- The project declares the semantic dependency.
- The provider supplies an implementation of that dependency.

Provider lock-in may be acceptable when deliberate. It should not be hidden inside configuration that appears to be generic.

---

## 7. Keep semantic categories distinct

Repository organization should reflect what things are, not just how they are built.

The main categories in this project are:

- A reusable C++ library with a public consumption story.
- Python applications and wrappers built on top of that native core.
- Examples that demonstrate use.
- Tests and consumer checks that verify behavior and packaging.
- Development, packaging, and environment tooling.

These categories should not leak into one another accidentally. An example should not silently become an installed product. A test target should not become part of the public package. A Python helper that is internal to the application layer should not be treated as a stable public API without an explicit decision.

Clear categories make it easier to change folder layout later without changing the repository's meaning.

---

## 8. Keep environment, packaging, and CI as outer layers

Development environments should provide tools, dependencies, runtimes, and useful variables. They should not secretly redefine the project workflow.

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
9. Remove superseded workflows rather than preserving ambiguous alternatives.
10. Update this philosophy only when the intended architecture changes, not when filenames or command spellings change.
