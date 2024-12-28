// src/api/cost-calculator.ts

import { PrismaClient } from '@prisma/client';
import { NextApiRequest, NextApiResponse } from 'next';

const prisma = new PrismaClient();

export type CostCalculationRequest = {
  quantity: number;
  panelSize: string;
  materialGrade: 'standard' | 'premium';
  supplierId: string;
};

export type MaterialCostBreakdown = {
  polyimide: number;
  aerogel: number;
  titanium: number;
  adhesive: number;
};

export type CostEstimateResponse = {
  materialCosts: MaterialCostBreakdown;
  processingCosts: number;
  totalCost: number;
  unitCost: number;
  validUntil: Date;
  supplier: {
    name: string;
    leadTime: number;
  };
};

export async function calculateCosts(
  req: NextApiRequest,
  res: NextApiResponse<CostEstimateResponse>
) {
  try {
    const { quantity, panelSize, materialGrade, supplierId } = req.body as CostCalculationRequest;

    // Get panel dimensions
    const panel = await prisma.panelSize.findFirst({
      where: { name: panelSize, active: true }
    });

    if (!panel) {
      return res.status(400).json({ error: 'Invalid panel size' });
    }

    // Get supplier information
    const supplier = await prisma.supplier.findUnique({
      where: { id: supplierId },
      include: {
        bulkDiscounts: {
          where: {
            validTo: null,
            minQuantity: {
              lte: quantity
            }
          },
          orderBy: {
            minQuantity: 'desc'
          },
          take: 1
        }
      }
    });

    if (!supplier) {
      return res.status(400).json({ error: 'Invalid supplier' });
    }

    // Get current material costs
    const materialCosts = await prisma.materialCost.findMany({
      where: {
        grade: materialGrade,
        validTo: null,
        supplierId
      }
    });

    // Calculate base material costs
    const materialCostBreakdown = calculateMaterialCosts(
      materialCosts,
      panel.area,
      quantity
    );

    // Apply bulk discount if applicable
    const bulkDiscount = supplier.bulkDiscounts[0]?.discount || 0;

    // Calculate processing costs
    const processingCosts = await calculateProcessingCosts(
      panel.area,
      quantity,
      supplier.costMultiplier
    );

    // Calculate total costs
    const subtotal = Object.values(materialCostBreakdown).reduce((a, b) => a + b, 0) + processingCosts;
    const totalCost = subtotal * (1 - bulkDiscount);
    const unitCost = totalCost / quantity;

    // Create cost estimate record
    const estimate = await prisma.costEstimate.create({
      data: {
        quantity,
        panelSize,
        materialGrade,
        supplier: supplier.name,
        materialCosts: materialCostBreakdown,
        processCosts: processingCosts,
        totalCost,
        unitCost,
        validFor: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days validity
        status: 'draft'
      }
    });

    return res.status(200).json({
      materialCosts: materialCostBreakdown,
      processingCosts,
      totalCost,
      unitCost,
      validUntil: estimate.validFor,
      supplier: {
        name: supplier.name,
        leadTime: supplier.leadTime
      }
    });

  } catch (error) {
    console.error('Cost calculation error:', error);
    return res.status(500).json({ error: 'Error calculating costs' });
  }
}

async function calculateMaterialCosts(
  materials: any[],
  area: number,
  quantity: number
): Promise<MaterialCostBreakdown> {
  const costs: MaterialCostBreakdown = {
    polyimide: 0,
    aerogel: 0,
    titanium: 0,
    adhesive: 0
  };

  for (const material of materials) {
    const baseAmount = area * (material.materialType === 'aerogel' ? 0.5 : 1); // aerogel uses 0.5kg/m²
    const wastage = 1 + material.wastageRate;
    costs[material.materialType] = material.basePrice * baseAmount * wastage * quantity;
  }

  return costs;
}

async function calculateProcessingCosts(
  area: number,
  quantity: number,
  supplierMultiplier: number
): Promise<number> {
  // Get current process costs
  const processCosts = await prisma.processCost.findMany({
    where: { validTo: null }
  });

  let totalProcessCost = 0;

  for (const process of processCosts) {
    const setupCost = process.setupCost;
    const processingCost = process.baseRate * area * quantity;
    totalProcessCost += (setupCost + processingCost);
  }

  return totalProcessCost * supplierMultiplier;
}
