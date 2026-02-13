# Architecture Standards

This document defines the **target architecture** for Your Organization projects.

> ⚠️ **Not all repositories follow this yet.**
> Always check the repo's `CLAUDE.md` for the **current state**.

## 1. Clean Architecture Principles

```
┌─────────────────────────────────────────────────┐
│                   Interface                      │
│            (Controller, DTO, Router)             │
└─────────────────────┬───────────────────────────┘
                      │ depends on
                      ▼
┌─────────────────────────────────────────────────┐
│                   Use Case                       │
│          (Business Logic, Service)               │
└─────────────────────┬───────────────────────────┘
                      │ depends on
                      ▼
┌─────────────────────────────────────────────────┐
│                    Domain                        │
│      (Entities, Repository Interfaces)           │
└─────────────────────▲───────────────────────────┘
                      │ implements
┌─────────────────────┴───────────────────────────┐
│                Infrastructure                    │
│        (Repository Impl, ORM, External)          │
└─────────────────────────────────────────────────┘
```

1. **Dependency Rule**: Dependencies point inward only.
2. **Domain Independence**: Domain layer has no framework dependencies.
3. **Interface Segregation**: Repository interfaces defined in Domain.

## 2. Layer Definitions

### Interface Layer
- **Role**: Handle HTTP/Input, Validate DTO, Call UseCase.
- **Rules**: No business logic here.

### Use Case Layer
- **Role**: Application Business Logic.
- **Rules**: Orchestrate domain entities. Dependent only on Domain.

### Domain Layer
- **Role**: Core Enterprise Logic & Data Structures.
- **Rules**: Pure Python/Dart/JS. No external lib dependencies.

### Infrastructure Layer
- **Role**: Gateway to external world (DB, API, File).
- **Rules**: Implement interfaces defined in Domain.

## 3. Clean Code Principles

1. **Single Responsibility (SRP)**: A class/function should have one reason to change.
2. **Meaningful Names**: Intent-revealing names.
3. **Small Functions**: Do one thing well.
4. **DRY (Don't Repeat Yourself)**: Extract common logic.
5. **YAGNI (You Aren't Gonna Need It)**: Don't engineer for future hypotheticals.

## 4. For AI Agents

1. **First**: Check repo's `CLAUDE.md` for current architecture status.
2. **If Clean Arch applied**: Follow the layer patterns strictly.
3. **If not applied**: Follow existing patterns, don't refactor without explicit ticket.
4. **When creating new features**: Prefer Clean Architecture patterns if repo supports it.
