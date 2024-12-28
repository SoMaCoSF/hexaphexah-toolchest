# Hexaphexah Project Documentation
Version: 1.0.0
Last Updated: 2024-12-28

## Project Overview
Hexaphexah is an advanced composite material system combining aerogel, polyimide, and titanium in a hexagonal grid structure for extreme thermal protection applications. This repository contains all necessary documentation, code, and specifications for development and production.

## Instructions for Composer Agent

### Initial Setup Tasks
1. Create project structure in `/cursor/Hexaphexah/`
2. Initialize database using provided schema
3. Setup development environment
4. Configure version control
5. Initialize testing framework

### Repository Structure
```
/cursor/Hexaphexah/
├── docs/                  # Documentation
├── src/                   # Source code
├── tests/                # Test files
├── models/               # 3D models and simulations
├── data/                # Reference data
└── tools/               # Development tools
```

## File Directory

| Filename | Format | Description | Purpose |
|----------|---------|-------------|----------|
| `main.rmd` | R Markdown | Main project documentation | Comprehensive project overview and technical specifications |
| `schema.prisma` | Prisma Schema | Database schema | Defines database structure and relationships |
| `blender_traditional.py` | Python | Blender modeling script | Creates composite visualization using traditional modeling |
| `blender_geometry_nodes.py` | Python | Blender geometry nodes script | Creates composite visualization using geometry nodes |
| `manufacturing_process.md` | Markdown | Manufacturing documentation | Detailed manufacturing procedures and specifications |
| `material_mapping.md` | Markdown