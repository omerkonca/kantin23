import React, { useState, useEffect } from 'react';
import { supabase } from '../../lib/supabase';
import { useAuthStore } from '../../store/authStore';
import { formatDate } from '../../utils/date';
import { formatCurrency } from '../../utils/currency';

export function SiparisGecmisiPage() {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const { user } = useAuthStore();

  useEffect(() => {
    if (user) {
      fetchSiparisler();
    }
  }, [user]);

  async function fetchSiparisler() {
    try {
      const { data, error } = await supabase
        .from('sales')
        .select(`
          *,
          products:product_id (name, price)
        `)
        .eq('user_id', user?.id)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setOrders(data || []);
    } catch (error) {
      console.error('Siparişler yüklenirken hata:', error);
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
      <h2 className="text-2xl font-bold text-gray-900">Sipariş Geçmişi</h2>

      <div className="bg-white shadow-sm rounded-lg overflow-hidden">
        <div className="divide-y divide-gray-200">
          {orders.map((order: any) => (
            <div key={order.id} className="p-6">
              <div className="flex justify-between items-start">
                <div>
                  <h3 className="text-lg font-medium text-gray-900">
                    {order.products.name}
                  </h3>
                  <p className="mt-1 text-sm text-gray-500">
                    {formatDate(order.created_at)}
                  </p>
                </div>
                <div className="text-right">
                  <p className="text-lg font-medium text-indigo-600">
                    {formatCurrency(order.total_price)}
                  </p>
                  <p className="mt-1 text-sm text-gray-500">
                    {order.quantity} adet
                  </p>
                </div>
              </div>
            </div>
          ))}

          {orders.length === 0 && (
            <div className="p-6 text-center text-gray-500">
              Henüz sipariş geçmişiniz bulunmuyor.
            </div>
          )}
        </div>
      </div>
    </div>
  );
}