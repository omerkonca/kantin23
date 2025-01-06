import React, { useState } from 'react';
import { supabase } from '../../lib/supabase';
import { Plus } from 'lucide-react';
import { useAuthStore } from '../../store/authStore';

interface UrunFormProps {
  onSuccess: () => void;
}

export function UrunForm({ onSuccess }: UrunFormProps) {
  const [name, setName] = useState('');
  const [price, setPrice] = useState('');
  const [stock, setStock] = useState('');
  const [loading, setLoading] = useState(false);
  const { user } = useAuthStore();

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!user) return;
    
    setLoading(true);

    try {
      const { error } = await supabase.from('products').insert([
        {
          name,
          price: parseFloat(price),
          stock: parseInt(stock),
          created_by: user.id // Kullanıcı ID'sini ekliyoruz
        },
      ]);

      if (error) throw error;

      setName('');
      setPrice('');
      setStock('');
      onSuccess();
    } catch (error) {
      console.error('Ürün eklenirken hata:', error);
      alert('Ürün eklenirken bir hata oluştu. Lütfen tekrar deneyin.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="bg-white rounded-lg shadow-sm p-6">
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-3">
        <div>
          <label className="block text-sm font-medium text-gray-700">Ürün Adı</label>
          <input
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
            required
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700">Fiyat (₺)</label>
          <input
            type="number"
            step="0.01"
            value={price}
            onChange={(e) => setPrice(e.target.value)}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
            required
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700">Stok</label>
          <input
            type="number"
            value={stock}
            onChange={(e) => setStock(e.target.value)}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
            required
          />
        </div>
      </div>
      <div className="mt-4">
        <button
          type="submit"
          disabled={loading}
          className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
        >
          <Plus className="h-4 w-4 mr-2" />
          {loading ? 'Ekleniyor...' : 'Ürün Ekle'}
        </button>
      </div>
    </form>
  );
}