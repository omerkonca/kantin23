import React, { useState } from 'react';
import { supabase } from '../../lib/supabase';
import { User } from '../../types';

interface KrediLimitFormProps {
  user: User;
  onSuccess: () => void;
}

export function KrediLimitForm({ user, onSuccess }: KrediLimitFormProps) {
  const [limit, setLimit] = useState(user.credit_limit?.toString() || '0');
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);

    try {
      const { error } = await supabase
        .from('profiles')
        .update({ credit_limit: parseFloat(limit) })
        .eq('id', user.id);

      if (error) throw error;
      onSuccess();
    } catch (error) {
      console.error('Kredi limiti güncellenirken hata:', error);
      alert('Kredi limiti güncellenirken bir hata oluştu.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <label className="block text-sm font-medium text-gray-700">
          Kredi Limiti (₺)
        </label>
        <input
          type="number"
          step="0.01"
          value={limit}
          onChange={(e) => setLimit(e.target.value)}
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
        />
      </div>
      <button
        type="submit"
        disabled={loading}
        className="w-full py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
      >
        {loading ? 'Güncelleniyor...' : 'Limiti Güncelle'}
      </button>
    </form>
  );
}