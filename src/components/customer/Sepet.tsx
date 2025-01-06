import React, { useState } from 'react';
import { supabase } from '../../lib/supabase';
import { Product } from '../../types';
import { useAuthStore } from '../../store/authStore';
import { formatCurrency } from '../../utils/currency';

interface SepetProps {
  sepet: Map<string, number>;
  urunler: Product[];
  onSuccess: () => void;
}

export function Sepet({ sepet, urunler, onSuccess }: SepetProps) {
  const [loading, setLoading] = useState(false);
  const [isCredit, setIsCredit] = useState(false);
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
      // Kullanıcı profili ve kredi limiti kontrolü
      const { data: profile } = await supabase
        .from('profiles')
        .select('balance, credit_limit')
        .eq('id', user.id)
        .single();

      if (!profile) {
        throw new Error('Kullanıcı profili bulunamadı');
      }

      if (!isCredit && profile.balance < toplam) {
        alert('Yetersiz bakiye!');
        return;
      }

      if (isCredit && (!profile.credit_limit || profile.credit_limit < toplam)) {
        alert('Yetersiz kredi limiti!');
        return;
      }

      // Satış işlemlerini gerçekleştir
      const sales = sepetUrunleri.map(({ urun, miktar }) => ({
        user_id: user.id,
        product_id: urun.id,
        quantity: miktar,
        total_price: urun.price * miktar,
        is_credit: isCredit,
        paid: !isCredit
      }));

      const { error: salesError } = await supabase.from('sales').insert(sales);
      if (salesError) throw salesError;

      // Veresiye satış ise kredi kaydı oluştur
      if (isCredit) {
        const dueDate = new Date();
        dueDate.setMonth(dueDate.getMonth() + 1);

        const { error: creditError } = await supabase.from('credits').insert({
          user_id: user.id,
          amount: toplam,
          paid_amount: 0,
          due_date: dueDate.toISOString()
        });

        if (creditError) throw creditError;
      } else {
        // Nakit satış ise bakiyeyi güncelle
        const { error: balanceError } = await supabase
          .from('profiles')
          .update({ balance: profile.balance - toplam })
          .eq('id', user.id);

        if (balanceError) throw balanceError;
      }

      // Stokları güncelle
      for (const { urun, miktar } of sepetUrunleri) {
        const { error: stockError } = await supabase
          .from('products')
          .update({ stock: urun.stock - miktar })
          .eq('id', urun.id);
        
        if (stockError) throw stockError;
      }

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
            <span>{formatCurrency(urun.price * miktar)}</span>
          </div>
        ))}
      </div>
      
      <div className="border-t pt-4">
        <div className="flex justify-between font-medium">
          <span>Toplam</span>
          <span>{formatCurrency(toplam)}</span>
        </div>
      </div>

      <div className="flex items-center space-x-2">
        <input
          type="checkbox"
          id="isCredit"
          checked={isCredit}
          onChange={(e) => setIsCredit(e.target.checked)}
          className="rounded text-indigo-600 focus:ring-indigo-500"
        />
        <label htmlFor="isCredit" className="text-sm text-gray-700">
          Veresiye
        </label>
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