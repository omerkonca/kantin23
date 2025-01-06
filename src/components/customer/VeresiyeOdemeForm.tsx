import React, { useState } from 'react';
import { supabase } from '../../lib/supabase';
import { Credit } from '../../types';
import { formatCurrency } from '../../utils/currency';

interface VeresiyeOdemeFormProps {
  credit: Credit;
  onSuccess: () => void;
}

export function VeresiyeOdemeForm({ credit, onSuccess }: VeresiyeOdemeFormProps) {
  const [amount, setAmount] = useState('');
  const [loading, setLoading] = useState(false);

  const remainingAmount = credit.amount - credit.paid_amount;

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!amount || parseFloat(amount) <= 0) return;
    setLoading(true);

    try {
      const paymentAmount = Math.min(parseFloat(amount), remainingAmount);
      
      const { error } = await supabase
        .from('credits')
        .update({
          paid_amount: credit.paid_amount + paymentAmount
        })
        .eq('id', credit.id);

      if (error) throw error;
      
      onSuccess();
      setAmount('');
    } catch (error) {
      console.error('Ödeme işlemi sırasında hata:', error);
      alert('Ödeme işlemi başarısız oldu.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <label className="block text-sm font-medium text-gray-700">
          Ödenecek Tutar (₺)
        </label>
        <input
          type="number"
          step="0.01"
          max={remainingAmount}
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
          required
        />
      </div>
      <div className="text-sm text-gray-500">
        Kalan Borç: {formatCurrency(remainingAmount)}
      </div>
      <button
        type="submit"
        disabled={loading || !amount || parseFloat(amount) <= 0}
        className="w-full py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
      >
        {loading ? 'İşleniyor...' : 'Ödeme Yap'}
      </button>
    </form>
  );
}