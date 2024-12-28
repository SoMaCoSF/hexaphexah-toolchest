import React, { useState, useEffect } from 'react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';

const CostCalculator = () => {
  const [quantity, setQuantity] = useState(100);
  const [manufacturer, setManufacturer] = useState('');
  const [materialGrade, setMaterialGrade] = useState('standard');
  const [panelSize, setPanelSize] = useState('500x500');
  const [costs, setCosts] = useState(null);
  const [loading, setLoading] = useState(false);

  // Simulated database values (would come from actual DB)
  const materialCosts = {
    standard: {
      polyimide: 120, // per m²
      aerogel: 250,   // per kg
      titanium: 180,  // per m²
      adhesive: 45    // per m²
    },
    premium: {
      polyimide: 180,
      aerogel: 350,
      titanium: 250,
      adhesive: 65
    }
  };

  const manufacturerRates = {
    aspen: 1.2,    // multiplier
    morgan: 1.35,
    rogers: 1.25
  };

  const wastageRates = {
    polyimide: 0.15,
    aerogel: 0.20,
    titanium: 0.25,
    adhesive: 0.10
  };

  const calculateCosts = () => {
    setLoading(true);
    
    // Panel area calculation
    const [width, height] = panelSize.split('x').map(Number);
    const area = (width * height) / 1000000; // convert to m²
    
    // Base material costs
    const baseCosts = {
      polyimide: materialCosts[materialGrade].polyimide * area,
      aerogel: materialCosts[materialGrade].aerogel * (area * 0.5), // assuming 0.5kg/m²
      titanium: materialCosts[materialGrade].titanium * area,
      adhesive: materialCosts[materialGrade].adhesive * area
    };
    
    // Add wastage
    Object.keys(baseCosts).forEach(material => {
      baseCosts[material] *= (1 + wastageRates[material]);
    });
    
    // Manufacturing costs
    const manufacturingCost = Object.values(baseCosts).reduce((a, b) => a + b, 0) 
      * manufacturerRates[manufacturer];
    
    // Scale by quantity with bulk discount
    const bulkDiscount = quantity > 500 ? 0.85 : quantity > 100 ? 0.9 : 1;
    
    const totalCost = (Object.values(baseCosts).reduce((a, b) => a + b, 0) 
      + manufacturingCost) * bulkDiscount * quantity;
    
    setCosts({
      materials: baseCosts,
      manufacturing: manufacturingCost,
      total: totalCost,
      perUnit: totalCost / quantity
    });
    
    setLoading(false);
  };

  return (
    <div className="w-full max-w-4xl mx-auto p-4">
      <Card>
        <CardHeader>
          <CardTitle>Hexaphexah Cost Calculator</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 gap-4 mb-6">
            <div>
              <label className="block mb-2">Quantity</label>
              <Input 
                type="number" 
                value={quantity} 
                onChange={(e) => setQuantity(Number(e.target.value))}
                min="1"
              />
            </div>
            
            <div>
              <label className="block mb-2">Manufacturer</label>
              <Select onValueChange={setManufacturer} value={manufacturer}>
                <SelectTrigger>
                  <SelectValue placeholder="Select manufacturer" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="aspen">Aspen Aerogels</SelectItem>
                  <SelectItem value="morgan">Morgan Advanced Materials</SelectItem>
                  <SelectItem value="rogers">Rogers Corporation</SelectItem>
                </SelectContent>
              </Select>
            </div>
            
            <div>
              <label className="block mb-2">Material Grade</label>
              <Select onValueChange={setMaterialGrade} value={materialGrade}>
                <SelectTrigger>
                  <SelectValue placeholder="Select grade" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="standard">Standard</SelectItem>
                  <SelectItem value="premium">Premium</SelectItem>
                </SelectContent>
              </Select>
            </div>
            
            <div>
              <label className="block mb-2">Panel Size (mm)</label>
              <Select onValueChange={setPanelSize} value={panelSize}>
                <SelectTrigger>
                  <SelectValue placeholder="Select size" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="500x500">500 x 500</SelectItem>
                  <SelectItem value="1000x500">1000 x 500</SelectItem>
                  <SelectItem value="1000x1000">1000 x 1000</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          
          <Button 
            onClick={calculateCosts} 
            className="w-full mb-6"
            disabled={loading || !manufacturer}
          >
            Calculate Costs
          </Button>
          
          {costs && (
            <div className="space-y-4">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Component</TableHead>
                    <TableHead className="text-right">Cost (USD)</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {Object.entries(costs.materials).map(([material, cost]) => (
                    <TableRow key={material}>
                      <TableCell className="capitalize">{material}</TableCell>
                      <TableCell className="text-right">${cost.toFixed(2)}</TableCell>
                    </TableRow>
                  ))}
                  <TableRow>
                    <TableCell>Manufacturing</TableCell>
                    <TableCell className="text-right">${costs.manufacturing.toFixed(2)}</TableCell>
                  </TableRow>
                  <TableRow>
                    <TableCell className="font-bold">Total Cost</TableCell>
                    <TableCell className="text-right font-bold">${costs.total.toFixed(2)}</TableCell>
                  </TableRow>
                  <TableRow>
                    <TableCell className="font-bold">Cost Per Unit</TableCell>
                    <TableCell className="text-right font-bold">${costs.perUnit.toFixed(2)}</TableCell>
                  </TableRow>
                </TableBody>
              </Table>
              
              <Alert>
                <AlertDescription>
                  These costs are estimates based on current market rates and may vary based on specific 
                  requirements, material availability, and manufacturer terms.
                </AlertDescription>
              </Alert>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
};

export default CostCalculator;
