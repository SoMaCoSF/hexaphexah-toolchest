// prisma/seed.ts

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  // Clear existing data
  await prisma.materialPriceHistory.deleteMany();
  await prisma.materialCost.deleteMany();
  await prisma.bulkDiscount.deleteMany();
  await prisma.certification.deleteMany();
  await prisma.contact.deleteMany();
  await prisma.supplier.deleteMany();
  await prisma.panelSize.deleteMany();
  await prisma.processCost.deleteMany();

  // Create suppliers
  const suppliers = await Promise.all([
    prisma.supplier.create({
      data: {
        name: 'Aspen Aerogels',
        type: 'manufacturer',
        costMultiplier: 1.2,
        leadTime: 14,
        minOrderValue: 5000,
        certifications: {
          create: [
            {
              type: 'ISO 9001',
              number: 'ISO9001-2024-001',
              issueDate: new Date('2024-01-01'),
              expiryDate: new Date('2026-12-31'),
              status: 'active'
            },
            {
              type: 'AS9100',
              number: 'AS9100-2023-123',
              issueDate: new Date('2023-06-01'),
              expiryDate: new Date('2026-05-31'),
              status: 'active'
            }
          ]
        },
        bulkDiscounts: {
          create: [
            { minQuantity: 100, discount: 0.05 },
            { minQuantity: 500, discount: 0.10 },
            { minQuantity: 1000, discount: 0.15 }
          ]
        }
      }
    }),
    prisma.supplier.create({
      data: {
        name: 'Morgan Advanced Materials',
        type: 'manufacturer',
        costMultiplier: 1.35,
        leadTime: 21,
        minOrderValue: 7500,
        certifications: {
          create: [
            {
              type: 'ISO 9001',
              number: 'ISO9001-2023-789',
              issueDate: new Date('2023-01-01'),
              expiryDate: new Date('2025-12-31'),
              status: 'active'
            }
          ]
        },
        bulkDiscounts: {
          create: [
            { minQuantity: 250, discount: 0.08 },
            { minQuantity: 750, discount: 0.12 },
            { minQuantity: 1500, discount: 0.18 }
          ]
        }
      }
    })
  ]);

  // Create material costs
  const materialCosts = await Promise.all(
    suppliers.map(supplier => 
      Promise.all([
        // Standard grade materials
        prisma.materialCost.create({
          data: {
            materialType: 'polyimide',
            grade: 'standard',
            basePrice: 120,
            unit: 'm²',
            wastageRate: 0.15,
            minimumOrder: 10,
            leadTime: 14,
            supplierId: supplier.id
          }
        }),
        prisma.materialCost.create({
          data: {
            materialType: 'aerogel',
            grade: 'standard',
            basePrice: 250,
            unit: 'kg',
            wastageRate: 0.20,
            minimumOrder: 5,
            leadTime: 21,
            supplierId: supplier.id
          }
        }),
        // Premium grade materials
        prisma.materialCost.create({
          data: {
            materialType: 'polyimide',
            grade: 'premium',
            basePrice: 180,
            unit: 'm²',
            wastageRate: 0.15,
            minimumOrder: 10,
            leadTime: 21,
            supplierId: supplier.id
          }
        }),
        prisma.materialCost.create({
          data: {
            materialType: 'aerogel',
            grade: 'premium',
            basePrice: 350,
            unit: 'kg',
            wastageRate: 0.20,
            minimumOrder: 5,
            leadTime: 28,
            supplierId: supplier.id
          }
        })
      ])
    )
  );

  // Create panel sizes
  const panelSizes = await Promise.all([
    prisma.panelSize.create({
      data: {
        name: '500x500',
        width: 500,
        height: 500,
        area: 0.25,
        active: true
      }
    }),
    prisma.panelSize.create({
      data: {
        name: '1000x500',
        width: 1000,
        height: 500,
        area: 0.5,
        active: true
      }
    }),
    prisma.panelSize.create({
      data: {
        name: '1000x1000',
        width: 1000,
        height: 1000,
        area: 1.0,
        active: true
      }
    })
  ]);

  // Create process costs
  const processCosts = await Promise.all([
    prisma.processCost.create({
      data: {
        processType: 'cutting',
        baseRate: 45.00,  // per hour
        setupCost: 150.00,
        currency: 'USD'
      }
    }),
    prisma.processCost.create({
      data: {
        processType: 'bonding',
        baseRate: 35.00,  // per hour
        setupCost: 100.00,
        currency: 'USD'
      }
    }),
    prisma.processCost.create({
      data: {
        processType: 'quality_control',
        baseRate: 40.00,  // per hour
        setupCost: 75.00,
        currency: 'USD'
      }
    })
  ]);

  // Create material compatibility rules
  const compatibilityRules = await Promise.all([
    prisma.materialCompatibility.create({
      data: {
        primaryMaterial: 'polyimide',
        secondaryMaterial: 'aerogel',
        compatible: true,
        notes: 'Standard bonding process'
      }
    }),
    prisma.materialCompatibility.create({
      data: {
        primaryMaterial: 'titanium',
        secondaryMaterial: 'polyimide',
        compatible: true,
        notes: 'Requires surface treatment'
      }
    })
  ]);

  console.log({
    suppliers: suppliers.length,
    materialCosts: materialCosts.flat().length,
    panelSizes: panelSizes.length,
    processCosts: processCosts.length,
    compatibilityRules: compatibilityRules.length
  });
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
