import React, { useState, useEffect } from 'react';
import { supabase } from '../../lib/supabase';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { formatCurrency } from '../../utils/currency';

export function RaporlarPage() {
  const [dailySales, setDailySales] = useState([]);
  const [topProducts, setTopProducts] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchRaporlar();
  }, []);

  async function fetchRaporlar() {
    try {
      // Günlük satışları al
      const { data: salesData } = await supabase
        .from('sales')
        .select('created_at, total_price')
        .order('created_at', { ascending: false })
        .limit(7);

      if (salesData) {
        const dailyTotals = salesData.reduce((acc: any, sale) => {
          const date = new Date(sale.created_at).toLocaleDateString('tr-TR');
          acc[date] = (acc[date] || 0) + sale.total_price;
          return acc;
        }, {});

        setDailySales(
          Object.entries(dailyTotals).map(([date, total]) => ({
            date,
            total
          }))
        );
      }

      // En çok satan ürünleri al
      const { data: productsData } = await supabase
        .from('sales')
        .select(`
          products:product_id (name),
          quantity,
          total_price
        `)
        .order('quantity', { ascending: false })
        .limit(5);

      if (productsData) {
        const productTotals = productsData.reduce((acc: any, sale) => {
          const productName = sale.products.name;
          if (!acc[productName]) {
            acc[productName] = { quantity: 0, total: 0 };
          }
          acc[productName].quantity += sale.quantity;
          acc[productName].total += sale.total_price;
          return acc;
        }, {});

        setTopProducts(
          Object.entries(productTotals).map(([name, data]: [string, any]) => ({
            name,
            ...data
          }))
        );
      }
    } catch (error) {
      console.error('Raporlar yüklenirken hata:', error);
    } finally {
      setLoading(false);
    }
  }

  if (loading) {
    return (
      <div className="flex justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold text-gray-900">Satış Raporları</h2>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Günlük Satışlar Grafiği */}
        <div className="bg-white p-6 rounded-lg shadow-sm">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Son 7 Günlük Satışlar</h3>
          <div className="h-80">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={dailySales}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" />
                <YAxis />
                <Tooltip formatter={(value) => formatCurrency(value)} />
                <Bar dataKey="total" fill="#4f46e5" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* En Çok Satan Ürünler */}
        <div className="bg-white p-6 rounded-lg shadow-sm">
          <h3 className="text-lg font-medium text-gray-900 mb-4">En Çok Satan Ürünler</h3>
          <div className="space-y-4">
            {topProducts.map((product: any) => (
              <div
                key={product.name}
                className="flex justify-between items-center border-b pb-4"
              >
                <div>
                  <p className="font-medium">{product.name}</p>
                  <p className="text-sm text-gray-500">{product.quantity} adet satıldı</p>
                </div>
                <p className="font-medium text-indigo-600">
                  {formatCurrency(product.total)}
                </p>
              </div>
            ))}
          </div>
        </div>
      </div>
     </div> 
  );
}