// src/utils/cost-calculator.ts

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export interface CostFactors {
  laborRate: number;
  overheadRate: number;
  profitMargin: number;
  wastageFactors: {
    polyimide: number;
    aerogel: number;
    titanium: number;
    adhesive: number;
  };
}

export interface ProductionEstimate {
  setupTime: number;
  productionTime: number;
  materialRequirements: {
    polyimide: number;
    aerogel: number;
    titanium: number;
    adhesive: number;
  };
  wastage: {
    polyimide: number;
    aerogel: number;
    titanium: number;
    adhesive: number;
  };
}

export class CostCalculator {
  private static DEFAULT_COST_FACTORS: CostFactors = {
    laborRate: 75.00,  // USD per hour
    overheadRate: 1.5, // 150% of labor cost
    profitMargin: 0.25, // 25%
    wastageFactors: {
      polyimide: 0.15,
      aerogel: 0.20,
      titanium: 0.25,
      adhesive: 0.10
    }
  };

  static async calculateProductionEstimate(
    quantity: number,
    panelSize: string,
    materialGrade: string
  ): Promise<ProductionEstimate> {
    const panel = await prisma.panelSize.findFirst({
      where: { name: panelSize, active: true }
    });

    if (!panel) {
      throw new Error('Invalid panel size');
    }

    // Calculate production times
    const setupTime = 2; // hours
    const productionTimePerUnit = 0.5; // hours
    const productionTime = quantity * productionTimePerUnit;

    // Calculate material requirements
    const baseRequirements = {
      polyimide: panel.area * 2, // m² (top and bottom layer)
      aerogel: panel.area * 0.5, // kg (based on density)
      titanium: panel.area, // m²
      adhesive: panel.area * 1.2 // m² (including overlap)
    };

    // Calculate wastage
    const wastage = {
      polyimide: baseRequirements.polyimide * this.DEFAULT_COST_FACTORS.wastageFactors.polyimide,
      aerogel: baseRequirements.aerogel * this.DEFAULT_COST_FACTORS.wastageFactors.aerogel,
      titanium: baseRequirements.titanium * this.DEFAULT_COST_FACTORS.wastageFactors.titanium,
      adhesive: baseRequirements.adhesive * this.DEFAULT_COST_FACTORS.wastageFactors.adhesive
    };

    return {
      setupTime,
      productionTime,
      materialRequirements: baseRequirements,
      wastage
    };
  }

  static calculateBulkDiscount(quantity: number): number {
    if (quantity >= 1000) return 0.15;
    if (quantity >= 500) return 0.10;
    if (quantity >= 100) return 0.05;
    return 0;
  }

  static async calculateLeadTime(
    quantity: number,
    supplierId: string
  ): Promise<number> {
    const supplier = await prisma.supplier.findUnique({
      where: { id: supplierId }
    });

    if (!supplier) {
      throw new Error('Invalid supplier');
    }

    // Base lead time from supplier
    let leadTime = supplier.leadTime;

    // Adjust based on quantity
    if (quantity > 1000) leadTime += 14;
    else if (quantity > 500) leadTime += 7;

    return leadTime;
  }

  static async validateMaterialCompatibility(
    materialCombinations: string[]
  ): Promise<boolean> {
    const compatibilityChecks = await Promise.all(
      materialCombinations.map(async (combo) => {
        const [primary, secondary] = combo.split('-');
        return prisma.materialCompatibility.findFirst({
          where: {
            primaryMaterial: primary,
            secondaryMaterial: secondary,
            compatible: true,
            validTo: null
          }
        });
      })
    );

    return compatibilityChecks.every(check => check !== null);
  }

  static calculateProcessingTime(area: number, quantity: number): number {
    // Base processing time in hours
    const baseTime = 0.5; // 30 minutes per unit
    const setupTime = 2; // 2 hours setup

    return setupTime + (baseTime * quantity * Math.sqrt(area));
  }

  static calculateQualityControlCosts(
    totalCost: number,
    complexity: 'low' | 'medium' | 'high'
  ): number {
    const qcRates = {
      low: 0.05,
      medium: 0.08,
      high: 0.12
    };

    return totalCost * qcRates[complexity];
  }

  static async getHistoricalPricing(
    materialType: string,
    grade: string,
    startDate: Date,
    endDate: Date
  ) {
    return prisma.materialPriceHistory.findMany({
      where: {
        material: {
          materialType,
          grade
        },
        date: {
          gte: startDate,
          lte: endDate
        }
      },
      orderBy: {
        date: 'asc'
      }
    });
  }

  static calculateROI(
    totalCost: number,
    expectedLifespan: number,
    energySavings: number,
    maintenanceCost: number
  ): number {
    const annualBenefit = energySavings - maintenanceCost;
    const roi = (annualBenefit * expectedLifespan - totalCost) / totalCost * 100;
    return Math.round(roi * 100) / 100;
  }
}

export async function generateCostReport(
  estimateId: string
): Promise<string> {
  const estimate = await prisma.costEstimate.findUnique({
    where: { id: estimateId },
    include: {
      supplier: true
    }
  });

  if (!estimate) {
    throw new Error('Estimate not found');
  }

  return `
Cost Estimate Report
===================
Date: ${estimate.createdAt.toLocaleDateString()}
Valid Until: ${estimate.validFor.toLocaleDateString()}

Material Costs
-------------
${Object.entries(estimate.materialCosts as object)
  .map(([material, cost]) => `${material}: $${cost.toFixed(2)}`)
  .join('\n')}

Processing Costs
---------------
Total: $${estimate.processCosts}

Summary
-------
Total Cost: $${estimate.totalCost.toFixed(2)}
Unit Cost: $${estimate.unitCost.toFixed(2)}
Lead Time: ${estimate.supplier.leadTime} days

Terms and Conditions
-------------------
- Prices valid for 30 days
- Lead time subject to material availability
- Minimum order quantities apply
- Pricing includes standard packaging
- Shipping costs not included
  `;
}
