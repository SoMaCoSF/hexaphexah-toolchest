---
title: "Advanced Composite Material Project Setup"
version: "1.0.0"
description: "Project initialization and structure for aerogel-polyimide composite development"
author: "Materials Engineering Team"
date: "2024-12-28"
---

# Project Initialization Guide for Cursor Composer Agent

## 1. Repository Setup

```bash
# Initialize new repository
gh repo create aerogel-composite-dev --private --clone
cd aerogel-composite-dev

# Create basic structure
mkdir -p {src,docs,tests,data,schemas,models}
mkdir -p src/{components,utils,database,visualization}
```

## 2. Project Structure
```
aerogel-composite-dev/
├── src/
│   ├── components/      # React/Three.js components
│   ├── database/        # Database connections and queries
│   ├── utils/           # Utility functions
│   └── visualization/   # Three.js visualization code
├── docs/               # Documentation
├── tests/              # Test files
├── data/              # Sample data and configurations
├── schemas/           # Database schemas
└── models/            # 3D models and material definitions
```

## 3. Environment Setup

```bash
# Create .env file
cat << EOF > .env
DATABASE_URL=postgresql://username:password@localhost:5432/aerogel_composite
GITHUB_TOKEN=your_token_here
EOF

# Create .gitignore
cat << EOF > .gitignore
node_modules/
.env
*.log
dist/
.DS_Store
EOF
```

## 4. Dependencies Installation

```bash
# Initialize Node.js project
npm init -y

# Install core dependencies
npm install three @react-three/fiber @react-three/drei pg prisma typescript
npm install -D @types/node @types/three ts-node

# Initialize TypeScript
npx tsc --init
```

## 5. Database Initialization Instructions for Composer Agent

```bash
# Create database
createdb aerogel_composite

# Initialize Prisma
npx prisma init

# Apply migrations after schema creation
npx prisma migrate dev --name init
```

## 6. Initial Commit Structure

```bash
# Initialize git repository
git init
git add .
git commit -m "Initial project setup"
git push -u origin main

# Create development branch
git checkout -b development
```

## Next Steps for Composer Agent:

1. Initialize database using schema artifact
2. Setup Three.js visualization environment
3. Create initial React components
4. Configure test environment
5. Setup CI/CD pipeline

Note: The material properties should align with Marvelous Designer's .zfab and .psp specifications for compatibility.
