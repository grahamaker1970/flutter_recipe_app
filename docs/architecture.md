# Architecture

## Overview
- Single-file Flutter application in `lib/main.dart`.
- SQLite persistence through `sqflite`.
- Main layers in code:
  - UI screens/widgets
  - Domain models
  - `DbService` repository-like service

## Domain Models
- `MasterRecipe`
  - `id`
  - `name`
  - `ingredients: List<IngredientItem>`
- `IngredientItem`
  - `name`
  - `baseAmount`
  - `currentAmount`
  - `unit` (optional string)
- `AdjustmentNote`
  - `id`
  - `recipeId`
  - `title`
  - `memo`
  - `createdAt`
  - `items: List<NoteItem>`
- `NoteItem`
  - `name`
  - `baseAmount`
  - `adjustedAmount`
  - `unit`

## Database
- DB version: `2`
- Migration strategy:
  - `v1 -> v2`: add `unit` columns with default empty string.

### Tables
- `recipes(id, name)`
- `ingredients(id, recipe_id, name, base_amount, unit)`
- `notes(id, recipe_id, title, memo, created_at)`
- `note_items(id, note_id, name, base_amount, adjusted_amount, unit)`

## Screen Responsibilities
- `RecipeListScreen`
  - List recipes
  - Navigate to edit, calculator, history
- `MasterRecipeEditorScreen`
  - Create/edit recipe and ingredient rows
  - Validate `name`, `base amount`, and optional `unit`
- `LiveCalculatorScreen`
  - Keep ratio and adjusted amounts synchronized
  - Show unit-aware base/adjusted values
- `HistoryScreen`
  - Show saved notes and item snapshots with unit-aware values
