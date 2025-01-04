import React, { useState } from 'react';
import { supabase } from '../../lib/supabase';
import { Product } from '../../types';
import { useAuthStore } from '../../store/authStore';

interface SepetProps {
  sepet: Map<string, number>;
  urunler: Product[];
  onSuccess: () => void;
}

export function Sepet({ sepet, urunler, onSuccess }: SepetProps) {
  const [loading, setLoading] = useState(false);
  const { user } = useAuthStore();

  const sepetUrunleri = Array.from(sepet.entries()).map(([id, miktar]) => ({
    urun: urunler.find(u => u.id === id)!,
    miktar
  }));

  const toplam = sepetUrunleri.reduce(
    (acc, { urun, miktar }) => acc + urun.price * miktar,
    0
  );

  async function siparisVer() {
    if (!user) return;
    setLoading(true);

    try {
      // Kullanıcı bakiyesini kontrol et
      const { data: profile } = await supabase
        .from('profiles')
        .select('balance')
        .eq('id', user.id)
        .single();

      if (!profile || profile.balance < toplam) {
        alert('Yetersiz bakiye!');
        return;
      }

      // Satış işlemlerini gerçekleştir
      const sales = sepetUrunleri.map(({ urun, miktar }) => ({
        user_id: user.id,
        product_id: urun.id,
        quantity: miktar,
        total_price: urun.price * miktar
      }));

      const { error: salesError } = await supabase.from('sales').insert(sales);
      if (salesError) throw salesError;

      // Stokları güncelle
      for (const { urun, miktar } of sepetUrunleri) {
        const { error: stockError } = await supabase
          .from('products')
          .update({ stock: urun.stock - miktar })
          .eq('id', urun.id);
        
        if (stockError) throw stockError;
      }

      // Bakiyeyi güncelle
      const { error: balanceError } = await supabase
        .from('profiles')
        .update({ balance: profile.balance - toplam })
        .eq('id', user.id);

      if (balanceError) throw balanceError;

      onSuccess();
    } catch (error) {
      console.error('Sipariş işlemi sırasında hata:', error);
      alert('Sipariş işlemi başarısız oldu.');
    } finally {
      setLoading(false);
    }
  }

  if (sepetUrunleri.length === 0) {
    return (
      <div className="bg-white rounded-lg shadow-sm p-4">
        <p className="text-gray-500 text-center">Sepetiniz boş</p>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-lg shadow-sm p-4 space-y-4">
      <h3 className="font-medium text-gray-900">Sepetiniz</h3>
      
      <div className="space-y-2">
        {sepetUrunleri.map(({ urun, miktar }) => (
          <div key={urun.id} className="flex justify-between text-sm">
            <span>{urun.name} x {miktar}</span>
            <span>₺{(urun.price * miktar).toFixed(2)}</span>
          </div>
        ))}
      </div>
      
      <div className="border-t pt-4">
        <div className="flex justify-between font-medium">
          <span>Toplam</span>
          <span>₺{toplam.toFixed(2)}</span>
        </div>
      </div>
      
      <button
        onClick={siparisVer}
        disabled={loading}
        className="w-full py-2 px-4 bg-indigo-600 text-white rounded-md hover:bg-indigo-700 disabled:opacity-50"
      >
        {loading ? 'İşleniyor...' : 'Siparişi Tamamla'}
      </button>
    </div>
  );
}