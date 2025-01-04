import React, { useState, useEffect } from 'react';
import { supabase } from '../../lib/supabase';
import { Product } from '../../types';
import { UrunCard } from '../../components/customer/UrunCard';
import { Sepet } from '../../components/customer/Sepet';
import { useAuthStore } from '../../store/authStore';

export function SiparisPage() {
  const [urunler, setUrunler] = useState<Product[]>([]);
  const [sepet, setSepet] = useState<Map<string, number>>(new Map());
  const [loading, setLoading] = useState(true);
  const { user } = useAuthStore();

  useEffect(() => {
    fetchUrunler();
  }, []);

  async function fetchUrunler() {
    try {
      const { data, error } = await supabase
        .from('products')
        .select('*')
        .gt('stock', 0)
        .order('name');

      if (error) throw error;
      setUrunler(data || []);
    } catch (error) {
      console.error('Ürünler yüklenirken hata:', error);
    } finally {
      setLoading(false);
    }
  }

  function sepeteEkle(urunId: string) {
    setSepet(prev => {
      const yeniSepet = new Map(prev);
      yeniSepet.set(urunId, (yeniSepet.get(urunId) || 0) + 1);
      return yeniSepet;
    });
  }

  function sepettenCikar(urunId: string) {
    setSepet(prev => {
      const yeniSepet = new Map(prev);
      const miktar = yeniSepet.get(urunId);
      if (miktar && miktar > 1) {
        yeniSepet.set(urunId, miktar - 1);
      } else {
        yeniSepet.delete(urunId);
      }
      return yeniSepet;
    });
  }

  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold text-gray-900">Sipariş Ver</h2>
      
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2">
          {loading ? (
            <div className="flex justify-center">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
            </div>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {urunler.map(urun => (
                <UrunCard
                  key={urun.id}
                  urun={urun}
                  miktar={sepet.get(urun.id) || 0}
                  onEkle={() => sepeteEkle(urun.id)}
                  onCikar={() => sepettenCikar(urun.id)}
                />
              ))}
            </div>
          )}
        </div>
        
        <div>
          <Sepet
            sepet={sepet}
            urunler={urunler}
            onSuccess={() => {
              setSepet(new Map());
              fetchUrunler();
            }}
          />
        </div>
      </div>
    </div>
  );
}